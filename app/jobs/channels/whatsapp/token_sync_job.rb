class Channels::Whatsapp::TokenSyncJob < ApplicationJob
  queue_as :low

  def perform(whatsapp_channel)
    whatsapp_channel.sync_token_expiry_date
  end
end
