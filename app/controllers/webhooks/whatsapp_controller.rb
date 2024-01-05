class Webhooks::WhatsappController < ActionController::API
  include MetaTokenVerifyConcern

  def process_payload
    Webhooks::WhatsappEventsJob.perform_later(params.to_unsafe_hash) if valid_event?
    head :ok
  end

  private

  def valid_token?(token)
    channel = Channel::Whatsapp.find_by(phone_number: params[:phone_number])
    whatsapp_webhook_verify_token = channel.provider_config['webhook_verify_token'] if channel.present?
    token == whatsapp_webhook_verify_token if whatsapp_webhook_verify_token.present?
  end

  def valid_event?
    processed_params = params[:entry].try(:first).try(:[], 'changes').try(:first).try(:[], 'value')
    if processed_params.try(:[], :statuses).present?
      status = processed_params[:statuses].first
      return status[:status] == 'failed'
    end
    return true
  end
end
