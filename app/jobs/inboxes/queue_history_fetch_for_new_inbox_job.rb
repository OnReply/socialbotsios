module Inboxes
  class QueueHistoryFetchForNewInboxJob < ApplicationJob
    queue_as :default

    # Number of days to fetch for new inboxes
    DEFAULT_DAYS = 730

    def perform(channel_id, fetch_days = DEFAULT_DAYS)
      channel = Channel::Email.find_by(id: channel_id)

      # Skip if channel not found or not IMAP enabled
      return if channel.nil? || !channel.imap_enabled?

      # Skip if history already fetched
      return if channel.history_fetched?

      Rails.logger.info "[NEW_INBOX] Queueing historical fetch for new inbox: #{channel.email}"

      # Queue the history fetch job
      FetchImapEmailInboxesHistoryJob.perform_later(channel.id, fetch_days)
    end
  end
end
