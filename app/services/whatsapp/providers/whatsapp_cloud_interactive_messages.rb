module Whatsapp::Providers::WhatsappCloudInteractiveMessages

  # Meta Docs https://developers.facebook.com/docs/whatsapp/guides/interactive-messages?locale=en_US#how-to-use-it
  include Whatsapp::Providers::WhatsappCloudInteractiveMessages::Buttons
  include Whatsapp::Providers::WhatsappCloudInteractiveMessages::List
  include Whatsapp::Providers::WhatsappCloudInteractiveMessages::Products

  def send_message(phone_number, message)
    if message.attachments.present?
      send_attachment_message(phone_number, message)
    elsif interactive_message?(message)
      send_interactive_mesage(phone_number, message)
    else
      send_text_message(phone_number, message)
    end
  end

  def interactive_message?(message)
    ( message.content_type == 'input_select' && 
      message.content_attributes.dig('message_payload', 'content', 'buttons').present? ) || 
    ( message.content_attributes.dig('type') == 'whatsappproducts' )
  end

  def send_interactive_mesage(phone_number, message)
    response = HTTParty.post(
      "#{phone_id_path}/messages",
      headers: api_headers,
      body: {
        messaging_product: 'whatsapp',
        to: phone_number,
        interactive: build_interactive_content(message),
        type: 'interactive'
      }.to_json
    )

    process_response(response)
  end

  def build_interactive_content(message)
    if message.content_attributes["type"] == 'whatsappproducts'
      return build_products_interactive_content(message)
    elsif message.content_attributes["items"].length <= 3
      return build_buttons_interactive_content(message)
    else
      return build_list_interactive_content(message)
    end
  end
end