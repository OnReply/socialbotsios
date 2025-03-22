namespace :email do
  desc 'Fetch historical emails for a specific channel'
  task :fetch_history, [:channel_id, :days] => :environment do |_t, args|
    channel_id = args[:channel_id]
    days = args[:days]&.to_i || 730

    if channel_id.blank?
      puts 'Error: Please provide a channel ID'
      puts 'Usage: rake email:fetch_history[channel_id,days]'
      exit(1)
    end

    channel = Channel::Email.find_by(id: channel_id)

    if channel.nil?
      puts "Error: Channel with ID #{channel_id} not found"
      exit(1)
    end

    unless channel.imap_enabled?
      puts "Error: Channel #{channel.email} does not have IMAP enabled"
      exit(1)
    end

    if channel.history_fetched? && ENV['FORCE'] != 'true'
      puts "Channel #{channel.email} already has history fetched."
      puts 'To fetch again, use FORCE=true'
      exit(0)
    end

    puts "Queueing history fetch for #{channel.email} with #{days} days..."
    Inboxes::FetchImapEmailInboxesHistoryJob.perform_later(channel.id, days)
    puts 'Job queued successfully'
  end

  desc 'Fetch historical emails for all channels'
  task :fetch_all_history, [:days] => :environment do |_t, args|
    days = args[:days]&.to_i || 730

    channels = Channel::Email.where(imap_enabled: true)

    if channels.empty?
      puts 'No IMAP-enabled channels found'
      exit(0)
    end

    channels = channels.reject(&:history_fetched?) if ENV['FORCE'] != 'true'

    if channels.empty?
      puts 'All channels have already had their history fetched.'
      puts 'To fetch again, use FORCE=true'
      exit(0)
    end

    puts "Queueing history fetch for #{channels.size} channels with #{days} days..."

    channels.each do |channel|
      puts "- Queueing #{channel.email}"
      Inboxes::FetchImapEmailInboxesHistoryJob.perform_later(channel.id, days)
    end

    puts 'All jobs queued successfully'
  end

  desc 'List all channels with history fetch status'
  task list_history_status: :environment do
    channels = Channel::Email.where(imap_enabled: true)

    if channels.empty?
      puts 'No IMAP-enabled channels found'
      exit(0)
    end

    puts 'Email Channels with History Status:'
    puts '-----------------------------------'

    channels.each do |channel|
      status = if channel.history_fetched?
                 "FETCHED (#{channel.history_fetched_days} days, on #{channel.history_fetched_at&.to_s(:long)})"
               else
                 'NOT FETCHED'
               end

      puts "#{channel.id} | #{channel.email} | #{status}"
    end
  end
end
