class Channels::Whatsapp::UpdateApiKeyJob < ApplicationJob
  queue_as :low

  def perform(id)
    whatsapp_channel = Channel::Whatsapp.find(id)
    whatsapp_channel.hit_update_token_webhook
  end

end