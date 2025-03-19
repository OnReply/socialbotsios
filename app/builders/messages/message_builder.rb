class Messages::MessageBuilder
  include ::FileTypeHelper
  attr_reader :message

  def initialize(user, conversation, params)
    @params = params
    @private = params[:private] || false
    @conversation = conversation
    @user = user
    @message_type = params[:message_type] || 'outgoing'
    @attachments = params[:attachments]
    @automation_rule = content_attributes&.dig(:automation_rule_id)
    return unless params.instance_of?(ActionController::Parameters)

    @in_reply_to = content_attributes&.dig(:in_reply_to)
    @items = content_attributes&.dig(:items)
  end

  def perform
    @message = @conversation.messages.build(message_params)
    clean_email_content if @conversation.inbox&.inbox_type == 'Email'
    process_attachments
    process_emails
    @message.save!
    @message
  end

  private

  # Extracts content attributes from the given params.
  # - Converts ActionController::Parameters to a regular hash if needed.
  # - Attempts to parse a JSON string if content is a string.
  # - Returns an empty hash if content is not present, if there's a parsing error, or if it's an unexpected type.
  def content_attributes
    params = convert_to_hash(@params)
    content_attributes = params.fetch(:content_attributes, {})

    return parse_json(content_attributes) if content_attributes.is_a?(String)
    return content_attributes if content_attributes.is_a?(Hash)

    {}
  end

  # Converts the given object to a hash.
  # If it's an instance of ActionController::Parameters, converts it to an unsafe hash.
  # Otherwise, returns the object as-is.
  def convert_to_hash(obj)
    return obj.to_unsafe_h if obj.instance_of?(ActionController::Parameters)

    obj
  end

  # Attempts to parse a string as JSON.
  # If successful, returns the parsed hash with symbolized names.
  # If unsuccessful, returns nil.
  def parse_json(content)
    JSON.parse(content, symbolize_names: true)
  rescue JSON::ParserError
    {}
  end

  def process_attachments
    return if @attachments.blank?

    @attachments.each do |uploaded_attachment|
      attachment = @message.attachments.build(
        account_id: @message.account_id,
        file: uploaded_attachment
      )

      attachment.file_type = if uploaded_attachment.is_a?(String)
                               file_type_by_signed_id(
                                 uploaded_attachment
                               )
                             else
                               file_type(uploaded_attachment&.content_type)
                             end
    end
  end

  def process_emails
    return unless @conversation.inbox&.inbox_type == 'Email'

    cc_emails = process_email_string(@params[:cc_emails])
    bcc_emails = process_email_string(@params[:bcc_emails])
    to_emails = process_email_string(@params[:to_emails])

    all_email_addresses = cc_emails + bcc_emails + to_emails
    validate_email_addresses(all_email_addresses)

    @message.content_attributes[:cc_emails] = cc_emails
    @message.content_attributes[:bcc_emails] = bcc_emails
    @message.content_attributes[:to_emails] = to_emails
  end

  def process_email_string(email_string)
    return [] if email_string.blank?

    email_string.gsub(/\s+/, '').split(',')
  end

  def validate_email_addresses(all_emails)
    all_emails&.each do |email|
      raise StandardError, 'Invalid email address' unless email.match?(URI::MailTo::EMAIL_REGEXP)
    end
  end

  def message_type
    if @conversation.inbox.channel_type != 'Channel::Api' && @message_type == 'incoming'
      raise StandardError, 'Incoming messages are only allowed in Api inboxes'
    end

    @message_type
  end

  def sender
    message_type == 'outgoing' ? (message_sender || @user) : @conversation.contact
  end

  def external_created_at
    @params[:external_created_at].present? ? { external_created_at: @params[:external_created_at] } : {}
  end

  def automation_rule_id
    @automation_rule.present? ? { content_attributes: { automation_rule_id: @automation_rule } } : {}
  end

  def campaign_id
    @params[:campaign_id].present? ? { additional_attributes: { campaign_id: @params[:campaign_id] } } : {}
  end

  def template_params
    @params[:template_params].present? ? { additional_attributes: { template_params: JSON.parse(@params[:template_params].to_json) } } : {}
  end

  def message_sender
    return if @params[:sender_type] != 'AgentBot'

    AgentBot.where(account_id: [nil, @conversation.account.id]).find_by(id: @params[:sender_id])
  end

  def message_params
    params = {
      account_id: @conversation.account_id,
      inbox_id: @conversation.inbox_id,
      message_type: message_type,
      content: @params[:content],
      private: @private,
      sender: sender,
      content_type: @params[:content_type],
      items: @items,
      in_reply_to: @in_reply_to,
      echo_id: @params[:echo_id],
      source_id: @params[:source_id]
    }

    # If this is an email message and has a message_id in content_attributes, use it as source_id
    if @params[:content_attributes].is_a?(Hash) &&
       @params[:content_attributes][:email].is_a?(Hash) &&
       @params[:content_attributes][:email][:message_id].present?
      params[:source_id] = @params[:content_attributes][:email][:message_id]
    end

    params.merge(external_created_at)
          .merge(automation_rule_id)
          .merge(campaign_id)
          .merge(template_params)
  end

  # Cleans up email content from nested history before storing
  def clean_email_content
    return unless @message.content.present?

    # Only process incoming email messages
    return unless @conversation.inbox&.inbox_type == 'Email' && @message.message_type == 'incoming'

    original_content = @message.content.to_s

    # Log original content for debugging
    Rails.logger.debug { "Original email content: #{original_content[0..100]}..." }

    # Step 1: Remove lines starting with '>' (quoted text)
    content = original_content.gsub(/^>.*$/m, '')

    # Step 2: Remove "On ... wrote:" patterns and everything after
    on_wrote_match = content.match(/On\s+.*wrote:/m)
    content = content[0...on_wrote_match.begin(0)] if on_wrote_match

    # Step 3: Also check for the specific pattern "Hi, I got it. On Wed, 19 Mar 2025..."
    period_match = content.match(/(.+?)\.\s+On\s+/m)
    content = period_match[1] + '.' if period_match

    # Step 4: Remove any HTML blockquotes and Gmail quote divs
    content = content.gsub(%r{<blockquote.*?</blockquote>}m, '')
    content = content.gsub(%r{<div class="gmail_quote".*?</div>}m, '')

    # Clean up the result
    content = content.strip

    # Only update if we've successfully cleaned the content
    if content.present?
      @message.content = content
      Rails.logger.debug { "Cleaned email content: #{content}" }
    else
      Rails.logger.debug { 'Cleaning produced empty content, keeping original' }
    end
  end
end
