#!/usr/bin/env ruby
# This script fetches historical emails for IMAP-enabled channels
# Run with: bundle exec rails runner scripts/fetch_email_history.rb

## Find all email channels with IMAP enabled
channels = Channel::Email.where(imap_enabled: true)

if channels.empty?
  puts 'No IMAP email channels found.'
  exit
end

puts 'Available email channels with IMAP enabled:'
channels.each_with_index do |channel, index|
  status = channel.history_fetched? ? '[HISTORY FETCHED]' : '[NOT FETCHED]'
  puts "#{index + 1}. #{channel.email} #{status}"
end

## Prompt for channel selection
print "\nSelect the channel number to fetch history (or 'all' for all channels): "
choice = gets.chomp

## Ask for the number of days back
print 'Enter the number of days back to fetch messages (e.g., 730 for 2 years): '
days = gets.chomp.to_i

if days <= 0
  puts 'Invalid number of days. Using default of 730 days (2 years).'
  days = 730
end

if choice.downcase == 'all'
  puts "\nQueuing history fetch for ALL channels with a #{days}-day interval..."

  unfetched_channels = channels.reject(&:history_fetched?)

  if unfetched_channels.empty?
    puts 'All channels have already had their history fetched. Nothing to do.'
    exit
  end

  unfetched_channels.each do |channel|
    puts "Queuing history fetch for #{channel.email}..."
    Inboxes::FetchImapEmailInboxesHistoryJob.perform_later(channel.id, days)
  end

  puts "\nSuccessfully queued #{unfetched_channels.size} channels for history fetching."
  puts 'This process will run in the background. Check logs for progress.'
else
  choice_num = choice.to_i - 1

  if choice_num >= 0 && choice_num < channels.length
    selected_channel = channels[choice_num]

    if selected_channel.history_fetched?
      print 'Channel already has history fetched. Fetch again? (y/n): '
      fetch_again = gets.chomp.downcase == 'y'

      unless fetch_again
        puts 'Operation cancelled.'
        exit
      end
    end

    puts "Queuing history fetch for #{selected_channel.email} with a #{days}-day interval..."
    Inboxes::FetchImapEmailInboxesHistoryJob.perform_later(selected_channel.id, days)

    puts 'Successfully queued history fetch job.'
    puts 'This process will run in the background. Check logs for progress.'
  else
    puts 'Invalid channel selection'
  end
end
