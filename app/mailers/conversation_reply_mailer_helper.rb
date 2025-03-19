module ConversationReplyMailerHelper
  def prepare_mail(cc_bcc_enabled)
    @options = {
      to: to_emails,
      from: email_from,
      reply_to: email_reply_to,
      subject: mail_subject,
      message_id: custom_message_id,
      in_reply_to: in_reply_to_email,
      references: references_email
    }

    if cc_bcc_enabled
      @options[:cc] = cc_bcc_emails[0]
      @options[:bcc] = cc_bcc_emails[1]
    end
    ms_smtp_settings
    google_smtp_settings
    set_delivery_method

    Rails.logger.info("Email sent from #{email_from} to #{to_emails} with subject #{mail_subject}")

    mail(@options)
  end

  # Get the correct sender email for a message depending on its type (incoming/outgoing)
  def get_sender_email(message)
    if message.message_type == 'incoming'
      # For incoming messages, use the sender's email (typically contact)
      message.sender&.email || @contact&.email || 'unknown@example.com'
    else
      # For outgoing messages, use the sender's email (agent) or inbox email
      message.sender&.email || @inbox&.email_address || @channel&.try(:email) || @account&.support_email || 'support@example.com'
    end
  end

  # Check if the message content already contains email quote formatting
  # Looks for common patterns like blockquotes or "On ... wrote:" text
  def message_has_quote?(content)
    return false if content.blank?

    # Check for HTML blockquote tags
    html_quote = content.include?('<blockquote')

    # Check for common email reply patterns
    # Gmail style pattern: "On Wed, Mar 19, 2025 at 12:11 PM, Name <email> wrote:"
    gmail_quote = content.match?(/On\s+\w+,\s+\w+\s+\d+,\s+\d{4}(?:\s+at)?\s+[\d:]+\s+(?:[AP]M)?,?\s+[\w\s]+\s+<[\w@.]+>\s+wrote:/)

    # Alternative Gmail style
    alt_gmail_quote = content.match?(/On\s+[\w\s,]+\s+at\s+[\d:]+\s+[AP]M,?\s+[\w\s]+\s+<[\w@.]+>\s+wrote:/)

    # Email client separator lines
    separator_line = content.include?('------------------------------') ||
                     content.include?('________________________________') ||
                     content.include?('===============================') ||
                     content.include?('------ Original Message ------') ||
                     content.include?('‐‐‐‐‐‐‐ Original Message ‐‐‐‐‐‐‐')

    # Outlook style headers
    outlook_quote = content.match?(/From:[\s\w<>@.]+Sent:[\s\w,:]+To:[\s\w<>@.]+(?:Cc:[\s\w<>@.]+)?Subject:/)

    # Check for multiple quoted messages (duplicate history)
    # This pattern looks for 2+ occurrences of "On ... wrote:" which indicates nested quotes
    multiple_quotes = content.scan(/On\s+\w+,\s+\w+\s+\d+,\s+\d{4}/).length > 1

    # Gmail conversation style with dashed separator and date stamp
    gmail_thread_format = content.match?(/-{2,}.*?(\*.*?\*.*?\|.*?Mar \d+, \d{4})/)

    # Modern Gmail with ">" quotation markers
    gmail_quote_markers = content.scan(/^>/).count > 3

    # Check for gmail formatting markers
    gmail_format_markers = content.include?('------------------------------ ') &&
                           (content.include?('| Mar') || content.include?('|Mar')) &&
                           content.include?('>')

    # Return true if any pattern is found
    html_quote || gmail_quote || alt_gmail_quote || outlook_quote ||
      separator_line || multiple_quotes || gmail_format_markers ||
      gmail_thread_format || gmail_quote_markers
  end

  private

  def google_smtp_settings
    return unless @inbox.email? && @channel.imap_enabled && @inbox.channel.google?

    smtp_settings = base_smtp_settings('smtp.gmail.com')

    @options[:delivery_method] = :smtp
    @options[:delivery_method_options] = smtp_settings
  end

  def ms_smtp_settings
    return unless @inbox.email? && @channel.imap_enabled && @inbox.channel.microsoft?

    smtp_settings = base_smtp_settings('smtp.office365.com')

    @options[:delivery_method] = :smtp
    @options[:delivery_method_options] = smtp_settings
  end

  def base_smtp_settings(domain)
    {
      address: domain,
      port: 587,
      user_name: @channel.imap_login,
      password: @channel.provider_config['access_token'],
      domain: domain,
      tls: false,
      enable_starttls_auto: true,
      openssl_verify_mode: 'none',
      authentication: 'xoauth2'
    }
  end

  def set_delivery_method
    return unless @inbox.inbox_type == 'Email' && @channel.smtp_enabled

    smtp_settings = {
      address: @channel.smtp_address,
      port: @channel.smtp_port,
      user_name: @channel.smtp_login,
      password: @channel.smtp_password,
      domain: @channel.smtp_domain,
      tls: @channel.smtp_enable_ssl_tls,
      enable_starttls_auto: @channel.smtp_enable_starttls_auto,
      openssl_verify_mode: @channel.smtp_openssl_verify_mode,
      authentication: @channel.smtp_authentication
    }

    @options[:delivery_method] = :smtp
    @options[:delivery_method_options] = smtp_settings
  end

  def email_smtp_enabled
    @inbox.inbox_type == 'Email' && @channel.smtp_enabled
  end

  def email_imap_enabled
    @inbox.inbox_type == 'Email' && @channel.imap_enabled
  end

  def email_oauth_enabled
    @inbox.inbox_type == 'Email' && (@channel.microsoft? || @channel.google?)
  end

  def email_from
    email_oauth_enabled || email_smtp_enabled ? channel_email_with_name : from_email_with_name
  end

  def email_reply_to
    email_imap_enabled ? @channel.email : reply_email
  end

  # Use channel email domain in case of account email domain is not set for custom message_id and in_reply_to
  def channel_email_domain
    return @account.inbound_email_domain if @account.inbound_email_domain.present?

    email = @inbox.channel.try(:email)
    email.present? ? email.split('@').last : raise(StandardError, 'Channel email domain not present.')
  end

  # Build the References header for proper email threading
  # This should include all previous message IDs in the conversation
  def references_email
    # Collect all message IDs in chronological order (oldest first)
    all_message_ids = []

    # Get all messages in this conversation with source_id (which would be their Message-ID)
    # Order by created_at ASC to get oldest messages first
    @conversation.messages.where.not(source_id: nil).order(created_at: :asc).each do |msg|
      source_id = msg.source_id
      # Ensure the source_id is properly formatted with angle brackets
      msg_id = source_id.start_with?('<') && source_id.end_with?('>') ? source_id : "<#{source_id}>"
      all_message_ids << msg_id unless all_message_ids.include?(msg_id)
    end

    # Also check in content_attributes.email.message_id for messages that might have this set
    # This is crucial for including external messages that were received but don't have source_id
    @conversation.messages.each do |msg|
      next unless msg.content_attributes && msg.content_attributes['email'] && msg.content_attributes['email']['message_id'].present?

      message_id = msg.content_attributes['email']['message_id']
      msg_id = message_id.start_with?('<') && message_id.end_with?('>') ? message_id : "<#{message_id}>"
      all_message_ids << msg_id unless all_message_ids.include?(msg_id)
    end

    # Also check in content_attributes.email.in_reply_to for references we should include
    # This helps preserve threading when replying to external messages
    @conversation.messages.each do |msg|
      next unless msg.content_attributes && msg.content_attributes['email'] && msg.content_attributes['email']['in_reply_to'].present?

      in_reply_to = msg.content_attributes['email']['in_reply_to']
      reply_id = in_reply_to.start_with?('<') && in_reply_to.end_with?('>') ? in_reply_to : "<#{in_reply_to}>"
      all_message_ids << reply_id unless all_message_ids.include?(reply_id)
    end

    # Include original message headers from current message being processed
    if @original_email_headers && @original_email_headers[:message_id].present?
      message_id = @original_email_headers[:message_id]
      msg_id = message_id.start_with?('<') && message_id.end_with?('>') ? message_id : "<#{message_id}>"
      all_message_ids << msg_id unless all_message_ids.include?(msg_id)
    end

    # Include the conversation reference as well for additional context
    conversation_ref = "<account/#{@account.id}/conversation/#{@conversation.uuid}@#{channel_email_domain}>"
    all_message_ids << conversation_ref unless all_message_ids.include?(conversation_ref)

    # If for some reason we have no message IDs, at least include the conversation reference
    all_message_ids << conversation_ref if all_message_ids.empty?

    # Finally, include in_reply_to of the current message
    in_reply_to = in_reply_to_email
    all_message_ids << in_reply_to if in_reply_to.present? && !all_message_ids.include?(in_reply_to)

    # The References header should join all IDs with spaces
    # Some clients format with newlines, but a simple space-separated list is most standard
    all_message_ids.join(' ')
  end
end
