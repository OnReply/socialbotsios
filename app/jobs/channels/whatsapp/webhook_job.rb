class Channels::Whatsapp::WebhookJob < ApplicationJob
  queue_as :low

  def perform(id)
    whatsapp_channel = Channel::Whatsapp.find(id)
    whatsapp_channel.hit_webhook
  end

end