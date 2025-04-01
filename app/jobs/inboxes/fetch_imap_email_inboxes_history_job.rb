require 'net/imap'

module Inboxes
  class FetchImapEmailInboxesHistoryJob < MutexApplicationJob
    queue_as :scheduled_jobs

    # Default number of days to fetch (2 years), can be overridden by ENV variable
    DEFAULT_DAYS = ENV.fetch('FETCH_IMAP_EMAILS_DAYS', 730).to_i

    # Maximum emails to fetch in a single run to avoid rate limits
    # Adjust as needed based on your server capacity and API limits
    MAX_EMAILS_PER_BATCH = 100

    # Number of seconds to wait between batches to avoid overloading the server
    BATCH_DELAY = 30

    def perform(channel_id, days_to_fetch = DEFAULT_DAYS)
      channel = Channel::Email.find_by(id: channel_id)

      return if channel.nil?
      return unless channel.imap_enabled?
      return if channel.history_fetched?

      Rails.logger.info "[IMAP::HISTORY] Starting historical email fetch for #{channel.email} (#{days_to_fetch} days)"

      # Create a mutex key for this channel to prevent concurrent fetches
      key = format(::Redis::Alfred::EMAIL_MESSAGE_MUTEX, inbox_id: channel.inbox.id)

      begin
        # Use the mutex lock
        with_lock(key, 30.minutes) do
          process_history_for_channel(channel, days_to_fetch)
        end
      rescue StandardError => e
        Rails.logger.error "[IMAP::HISTORY] Error fetching history for #{channel.email}: #{e.message}"
        Rails.logger.error e.backtrace.join("\n")
        # Don't raise the error, we want to continue with marking history as fetched
      end

      # After successful fetch or error, ensure we mark history as fetched
      begin
        channel = Channel::Email.find(channel_id)
        mark_history_fetched(channel, days_to_fetch)
        Rails.logger.info "[IMAP::HISTORY] Successfully marked history as fetched for #{channel.email}"
      rescue StandardError => e
        Rails.logger.error "[IMAP::HISTORY] Error marking history as fetched: #{e.message}"
        raise e # Re-raise this error as it's critical
      end

      # After successful fetch, schedule resolution of conversations
      begin
        channel = Channel::Email.find(channel_id)
        conversations_to_update = channel.inbox.conversations
                                         .where('created_at > ?', days_to_fetch.days.ago)
                                         .where.not(status: :resolved) # Only update non-resolved conversations
                                         .order(created_at: :desc)     # Get most recent first
                                         .limit(300)                   # Limit to last 300 emails

        Rails.logger.info "[IMAP::HISTORY] Found #{conversations_to_update.count} conversations to update for #{channel.email}"

        if conversations_to_update.exists?
          # Process conversations in batches of 50
          conversations_to_update.in_batches(of: 50) do |batch|
            # Schedule each batch to be processed after 1 minute
            ResolveHistoricalConversationsBatchJob.set(wait: 1.minute).perform_later(batch.pluck(:id))
          end

          Rails.logger.info "[IMAP::HISTORY] Scheduled resolution for #{conversations_to_update.count} conversations in batches for #{channel.email}"
        else
          Rails.logger.info "[IMAP::HISTORY] No conversations found to update for #{channel.email}"
        end
      rescue StandardError => e
        Rails.logger.error "[IMAP::HISTORY] Error scheduling conversation resolution: #{e.message}"
        # Don't raise this error as the main job is complete
      end
    end

    private

    def process_history_for_channel(channel, days)
      Rails.logger.info "[IMAP::HISTORY] Processing historical emails for #{channel.email}"

      # Connect to IMAP server
      imap_client = build_imap_client(channel)

      begin
        # Calculate the date range
        end_date = Date.today
        start_date = end_date - days
        since_date = start_date.strftime('%d-%b-%Y')

        Rails.logger.info "[IMAP::HISTORY] Searching for emails since #{since_date}"

        # Search for messages in the date range
        seq_nums = imap_client.search(['SINCE', since_date])
        total_emails = seq_nums.length

        Rails.logger.info "[IMAP::HISTORY] Found #{total_emails} emails for #{channel.email}"

        if total_emails == 0
          # No emails found, mark as complete
          mark_history_fetched(channel, days)
          return
        end

        # Process emails in batches
        process_in_batches(channel, imap_client, seq_nums)

        # Mark history as fetched once all emails are processed
        mark_history_fetched(channel, days)

        Rails.logger.info "[IMAP::HISTORY] Completed historical fetch for #{channel.email}"
      rescue StandardError => e
        Rails.logger.error "[IMAP::HISTORY] Error in history fetch: #{e.message}"
        Rails.logger.error e.backtrace.join("\n")
        raise e
      ensure
        # Always disconnect from IMAP server
        terminate_imap_connection(imap_client)
      end
    end

    def process_in_batches(channel, imap_client, seq_nums)
      total_emails = seq_nums.length
      total_batches = (total_emails.to_f / MAX_EMAILS_PER_BATCH).ceil

      Rails.logger.info "[IMAP::HISTORY] Processing #{total_emails} emails in #{total_batches} batches"

      processed_count = 0
      # Process in batches to avoid rate limits
      seq_nums.each_slice(MAX_EMAILS_PER_BATCH).with_index do |batch, batch_index|
        Rails.logger.info "[IMAP::HISTORY] Processing batch #{batch_index + 1}/#{total_batches} (#{batch.size} emails)"

        # Process this batch
        process_batch(channel, imap_client, batch)
        processed_count += batch.size

        Rails.logger.info "[IMAP::HISTORY] Processed #{processed_count}/#{total_emails} emails so far"

        # Sleep between batches to avoid overwhelming the server
        if batch_index < total_batches - 1
          Rails.logger.info "[IMAP::HISTORY] Sleeping for #{BATCH_DELAY} seconds before next batch"
          sleep(BATCH_DELAY) unless Rails.env.test?
        end
      end

      Rails.logger.info "[IMAP::HISTORY] Completed processing all #{processed_count} emails"
    end

    def process_batch(channel, imap_client, seq_nums)
      # Get message IDs for the sequence numbers
      message_ids_with_seq = fetch_message_ids(imap_client, seq_nums)

      # Filter out messages that already exist in the system
      new_message_ids = filter_existing_messages(channel, message_ids_with_seq)

      # Fetch and process new messages
      new_message_ids.each do |seq_no, message_id|
        fetch_and_process_message(channel, imap_client, seq_no, message_id)
      end
    end

    def fetch_message_ids(imap_client, seq_nums)
      message_ids_with_seq = []

      seq_nums.each_slice(10) do |batch|
        batch_message_ids = imap_client.fetch(batch, 'BODY.PEEK[HEADER]')

        if batch_message_ids.blank?
          Rails.logger.info '[IMAP::HISTORY] Fetching batch headers failed'
          next
        end

        batch_message_ids.each do |data|
          header = data.attr['BODY[HEADER]']
          message = Mail.read_from_string(header)
          message_id = message.message_id

          message_ids_with_seq.push([data.seqno, message_id]) if message_id.present?
        end
      end

      message_ids_with_seq
    end

    def filter_existing_messages(channel, message_ids_with_seq)
      filtered = []

      message_ids_with_seq.each do |seq_no, message_id|
        # Skip if message already exists in the system
        filtered << [seq_no, message_id] unless message_exists?(channel, message_id)
      end

      Rails.logger.info "[IMAP::HISTORY] Found #{filtered.size} new messages out of #{message_ids_with_seq.size} total"
      filtered
    end

    def message_exists?(channel, message_id)
      channel.inbox.messages.where(source_id: message_id).exists?
    end

    def fetch_and_process_message(channel, imap_client, seq_no, message_id)
      # Fetch the full email
      fetch_data = imap_client.fetch(seq_no, 'RFC822')
      return if fetch_data.blank?

      mail_str = fetch_data[0].attr['RFC822']
      return if mail_str.blank?

      # Parse the email
      mail = Mail.read_from_string(mail_str)

      # Process the email
      Imap::ImapMailbox.new.process(mail, channel)

      Rails.logger.info "[IMAP::HISTORY] Processed email with ID: #{message_id}"
    rescue StandardError => e
      Rails.logger.error "[IMAP::HISTORY] Error processing email #{message_id}: #{e.message}"
    end

    def build_imap_client(channel)
      Rails.logger.info "[IMAP::HISTORY] Connecting to IMAP server for #{channel.email}"

      imap = Net::IMAP.new(channel.imap_address, port: channel.imap_port, ssl: true)

      auth_type = if channel.google?
                    'XOAUTH2'
                  else
                    'PLAIN'
                  end

      password = if channel.google?
                   Google::RefreshOauthTokenService.new(channel: channel).access_token
                 elsif channel.microsoft?
                   Microsoft::RefreshOauthTokenService.new(channel: channel).access_token
                 else
                   channel.imap_password
                 end

      imap.authenticate(auth_type, channel.imap_login, password)
      imap.select('INBOX')

      Rails.logger.info "[IMAP::HISTORY] Connected to IMAP server for #{channel.email}"
      imap
    end

    def terminate_imap_connection(imap)
      return if imap.nil?

      begin
        imap.logout
      rescue Net::IMAP::Error => e
        Rails.logger.info "[IMAP::HISTORY] Logout failed: #{e.message}"
        begin
          imap.disconnect
        rescue StandardError
          nil
        end
      end
    end

    def mark_history_fetched(channel, days)
      channel.update(
        history_fetched: true,
        history_fetched_at: Time.current,
        history_fetched_days: days
      )
      Rails.logger.info "[IMAP::HISTORY] Marked history as fetched for #{channel.email}"
    end
  end
end
