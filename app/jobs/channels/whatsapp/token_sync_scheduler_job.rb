class Channels::Whatsapp::TokenSyncSchedulerJob < ApplicationJob
  queue_as :low

  def perform()
    whatsapp_cloud_channels = Channel::Whatsapp.where(provider: 'whatsapp_cloud').find_in_batches do |batch|
      batch.each do |channel|
        channel.sync_token_expiry_date
      end
    end
  end
end