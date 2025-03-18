class ConversationReplyMailer < ApplicationMailer
  include ConversationReplyMailerHelper
  default from: ENV.fetch('MAILER_SENDER_EMAIL', 'Chatwoot <accounts@chatwoot.com>')
  layout :choose_layout

  def reply_with_summary(conversation, last_queued_id)
    return unless smtp_config_set_or_development?

    init_conversation_attributes(conversation)
    return if conversation_already_viewed?

    recap_messages = @conversation.messages.chat.where('id < ?', last_queued_id).last(10)
    new_messages = @conversation.messages.chat.where('id >= ?', last_queued_id)
    @messages = recap_messages + new_messages
    @messages = @messages.select(&:email_reply_summarizable?)
    prepare_mail(true)
  end

  def reply_without_summary(conversation, last_queued_id)
    return unless smtp_config_set_or_development?

    init_conversation_attributes(conversation)
    return if conversation_already_viewed?

    @messages = @conversation.messages.chat.where(message_type: [:outgoing, :template]).where('id >= ?', last_queued_id)
    @messages = @messages.reject { |m| m.template? && !m.input_csat? }
    return false if @messages.count.zero?

    prepare_mail(false)
  end

  def email_reply(message)
    return unless smtp_config_set_or_development?

    init_conversation_attributes(message.conversation)
    @message = message

    # Set up email history for email channels
    if @inbox.inbox_type == 'Email'
      # Make sure we have access to previous messages for the template
      # Order by created_at DESC to get the most recent messages first
      # Limit to 5 messages to ensure reliable email delivery and proper quoted format
      # Going beyond 5 messages can cause issues with email delivery and formatting
      @previous_messages = @conversation.messages.chat
                                        .where.not(id: @message.id)
                                        .where(message_type: [:incoming, :outgoing])
                                        .order(created_at: :desc)
                                        .limit(8) # Keep this at 5 for reliable email delivery

      # Don't strip HTML tags as we want to preserve the original format
      # Just ensure the content is properly formatted
      @previous_messages.each do |prev_msg|
        # Ensure content is not nil
        prev_msg.content = prev_msg.content.to_s

        # Truncate very long messages to prevent email delivery issues
        prev_msg.content = prev_msg.content[0..9997] + '...' if prev_msg.content.length > 10_000
      end
    end

    reply_mail_object = prepare_mail(true)

    # Extract the message_id without angle brackets for storage
    message_id = reply_mail_object.message_id
    message_id = message_id[1..-2] if message_id.start_with?('<') && message_id.end_with?('>')

    # Update the message with the source_id
    message.update(source_id: message_id)
  end

  def conversation_transcript(conversation, to_email)
    return unless smtp_config_set_or_development?

    init_conversation_attributes(conversation)

    @messages = @conversation.messages.chat.select(&:conversation_transcriptable?)

    Rails.logger.info("Email sent from #{from_email_with_name} \
      to #{to_email} with subject #{@conversation.display_id} \
      #{I18n.t('conversations.reply.transcript_subject')} ")
    mail({
           to: to_email,
           from: from_email_with_name,
           subject: "[##{@conversation.display_id}] #{I18n.t('conversations.reply.transcript_subject')}"
         })
  end

  private

  def init_conversation_attributes(conversation)
    @conversation = conversation
    @account = @conversation.account
    @contact = @conversation.contact
    @agent = @conversation.assignee
    @inbox = @conversation.inbox
    @channel = @inbox.channel
  end

  def should_use_conversation_email_address?
    @inbox.inbox_type == 'Email' || inbound_email_enabled?
  end

  def conversation_already_viewed?
    # whether contact already saw the message on widget
    return unless @conversation.contact_last_seen_at
    return unless last_outgoing_message&.created_at

    @conversation.contact_last_seen_at > last_outgoing_message&.created_at
  end

  def last_outgoing_message
    @conversation.messages.chat.where.not(message_type: :incoming)&.last
  end

  def sender_name(sender_email)
    if @inbox.friendly?
      I18n.t('conversations.reply.email.header.friendly_name', sender_name: custom_sender_name, business_name: business_name,
                                                               from_email: sender_email)
    else
      I18n.t('conversations.reply.email.header.professional_name', business_name: business_name, from_email: sender_email)
    end
  end

  def current_message
    @message || @conversation.messages.outgoing.last
  end

  def custom_sender_name
    current_message&.sender&.available_name || @agent&.available_name || 'Notifications'
  end

  def business_name
    @inbox.business_name || @inbox.name
  end

  def from_email
    should_use_conversation_email_address? ? parse_email(@account.support_email) : parse_email(inbox_from_email_address)
  end

  def mail_subject
    subject = @conversation.additional_attributes['mail_subject']
    return "[##{@conversation.display_id}] #{I18n.t('conversations.reply.email_subject')}" if subject.nil?

    chat_count = @conversation.messages.chat.count
    if chat_count > 1
      "Re: #{subject}"
    else
      subject
    end
  end

  def reply_email
    if should_use_conversation_email_address?
      sender_name("reply+#{@conversation.uuid}@#{@account.inbound_email_domain}")
    else
      @inbox.email_address || @agent&.email
    end
  end

  def from_email_with_name
    sender_name(from_email)
  end

  def channel_email_with_name
    sender_name(@channel.email)
  end

  def parse_email(email_string)
    Mail::Address.new(email_string).address
  end

  def inbox_from_email_address
    return @inbox.email_address if @inbox.email_address

    @account.support_email
  end

  def custom_message_id
    last_message = @message || @messages&.last
    message_id = nil

    if last_message&.id
      # Create a unique message ID that includes the conversation UUID and message ID
      "<conversation/#{@conversation.uuid}/messages/#{last_message.id}/#{Time.now.to_i}@#{channel_email_domain}>"
    else
      # Fallback to a generic message ID if no message is available
      "<conversation/#{@conversation.uuid}/#{Time.now.to_i}@#{channel_email_domain}>"
    end
  end

  def in_reply_to_email
    conversation_reply_email_id || "<account/#{@account.id}/conversation/#{@conversation.uuid}@#{channel_email_domain}>"
  end

  def conversation_reply_email_id
    # Try to get the message_id from the last incoming message
    content_attributes = @conversation.messages.incoming.last&.content_attributes

    if content_attributes && content_attributes['email'] && content_attributes['email']['message_id']
      message_id = content_attributes['email']['message_id']
      # Ensure the message_id is properly formatted with angle brackets
      return message_id.start_with?('<') && message_id.end_with?('>') ? message_id : "<#{message_id}>"
    end

    # If no incoming message with message_id is found, try to use the source_id from the last message
    last_message_with_source = @conversation.messages.where.not(source_id: nil).last
    if last_message_with_source.present?
      source_id = last_message_with_source.source_id
      return source_id.start_with?('<') && source_id.end_with?('>') ? source_id : "<#{source_id}>"
    end

    nil
  end

  def cc_bcc_emails
    content_attributes = @conversation.messages.outgoing.last&.content_attributes

    return [] unless content_attributes
    return [] unless content_attributes[:cc_emails] || content_attributes[:bcc_emails]

    [content_attributes[:cc_emails], content_attributes[:bcc_emails]]
  end

  def to_emails_from_content_attributes
    content_attributes = @conversation.messages.outgoing.last&.content_attributes

    return [] unless content_attributes
    return [] unless content_attributes[:to_emails]

    content_attributes[:to_emails]
  end

  def to_emails
    # if there is no to_emails from content_attributes, send it to @contact&.email
    to_emails_from_content_attributes.presence || [@contact&.email]
  end

  def inbound_email_enabled?
    @inbound_email_enabled ||= @account.feature_enabled?('inbound_emails') && @account.inbound_email_domain
                                                                                      .present? && @account.support_email.present?
  end

  def choose_layout
    return false if action_name == 'reply_without_summary' || action_name == 'email_reply'

    'mailer/base'
  end
end
