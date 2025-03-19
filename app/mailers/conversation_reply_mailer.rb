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

    # Log message information for debugging
    Rails.logger.debug { "Processing email reply for message ID: #{@message.id}" }

    # Check if the message already contains quote formatting
    has_existing_history = message_has_quote?(@message.content.to_s)
    Rails.logger.debug { "Message has existing history: #{has_existing_history}" }

    # Set up email history for email channels, but only if the message doesn't already have quotes
    if @inbox.inbox_type == 'Email' && !has_existing_history
      # Get previous messages in reverse chronological order (most recent first)
      @previous_messages = @conversation.messages.chat
                                        .where.not(id: @message.id)
                                        .where(message_type: [:incoming, :outgoing])
                                        .order(created_at: :desc)
                                        .limit(10) # Keep this at 10 for reliable email delivery

      Rails.logger.debug { "Added #{@previous_messages.size} previous messages to the email history" }

      # Only clean/process incoming messages to remove quoted parts
      @previous_messages.each do |prev_msg|
        if prev_msg.message_type == 'incoming'
          # Process incoming messages to remove any quoted text
          original_content = prev_msg.content.to_s
          Rails.logger.debug { "Processing incoming message: #{original_content[0..100]}..." }

          # Apply cleaning only to incoming messages
          # Step 1: Remove lines starting with '>' (quoted text)
          clean_content = original_content.gsub(/^>.*$/m, '')

          # Step 2: Remove "On ... wrote:" patterns and everything after
          on_wrote_match = clean_content.match(/On\s+.*wrote:/m)
          clean_content = clean_content[0...on_wrote_match.begin(0)] if on_wrote_match

          # Step 3: Also check for the pattern "Hi, I got it. On Wed, 19 Mar 2025..."
          period_match = clean_content.match(/(.+?)\.\s+On\s+/m)
          clean_content = period_match[1] + '.' if period_match

          # Step 4: Remove any HTML blockquotes and Gmail quote divs
          clean_content = clean_content.gsub(%r{<blockquote.*?</blockquote>}m, '')
          clean_content = clean_content.gsub(%r{<div class="gmail_quote".*?</div>}m, '')

          # Clean up the result
          clean_content = clean_content.strip

          # Update the message content, but only if cleaning produced something
          if clean_content.present?
            prev_msg.content = clean_content
            Rails.logger.debug { "Cleaned incoming message: #{clean_content}" }
          end
        end

        # Truncate very long messages to prevent email delivery issues
        prev_msg.content = prev_msg.content[0..9997] + '...' if prev_msg.content.length > 10_000
      end
    end

    # Always extract original email headers for proper reply-all functionality
    @original_email_headers = extract_email_headers_from_previous_message

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

  def extract_email_headers_from_previous_message
    # Try to extract email headers from the last incoming message for reply-all support
    last_incoming = @conversation.messages.incoming.last
    return {} unless last_incoming&.content_attributes&.dig(:email).present?

    email_attrs = last_incoming.content_attributes[:email] || {}
    {
      from: email_attrs[:from],
      to: email_attrs[:to],
      cc: email_attrs[:cc],
      message_id: email_attrs[:message_id],
      in_reply_to: email_attrs[:in_reply_to]
    }
  end

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
    # First check if we have an original email to reply to from the incoming message
    if @original_email_headers && @original_email_headers[:message_id].present?
      message_id = @original_email_headers[:message_id]
      return message_id.start_with?('<') && message_id.end_with?('>') ? message_id : "<#{message_id}>"
    end

    # Fall back to conversation_reply_email_id
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
    # First try to get CC/BCC from current message's content attributes
    content_attributes = current_message&.content_attributes

    if content_attributes && (content_attributes[:cc_emails] || content_attributes[:bcc_emails])
      return [content_attributes[:cc_emails], content_attributes[:bcc_emails]]
    end

    # If no CC/BCC in current message, try to get from original email headers for reply-all
    if @original_email_headers && @original_email_headers[:cc].present?
      # For reply-all, use original CC recipients except our own addresses
      our_addresses = [@channel.email, @inbox.email_address, @account.support_email].compact
      cc_emails = @original_email_headers[:cc].reject { |email| our_addresses.include?(email) }
      return [cc_emails, []]
    end

    # No CC/BCC found
    [[], []]
  end

  def to_emails_from_content_attributes
    # First check content attributes
    content_attributes = current_message&.content_attributes

    return content_attributes[:to_emails] if content_attributes && content_attributes[:to_emails].present?

    # For reply-all, combine original recipient and sender (except our own address)
    if @original_email_headers
      recipients = []

      # Add the original sender (the person we're replying to) first
      recipients += @original_email_headers[:from] if @original_email_headers[:from].present?

      # Add original TO recipients (except our own addresses and the contact email)
      if @original_email_headers[:to].present?
        our_addresses = [@channel.email, @inbox.email_address, @account.support_email, @contact&.email].compact
        recipients += @original_email_headers[:to].reject { |email| our_addresses.include?(email) }
      end

      return recipients.uniq if recipients.present?
    end

    # No recipients found in content attributes or original headers
    []
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
