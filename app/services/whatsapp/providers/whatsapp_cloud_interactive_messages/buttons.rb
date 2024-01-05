module Whatsapp::Providers::WhatsappCloudInteractiveMessages::Buttons
  include Whatsapp::Providers::WhatsappCloudInteractiveMessages::Base

  def build_buttons_interactive_content(message)
    data = {
      'type': 'button',
      'body': {
        'text': "#{message.content}"
      },
      'action': {
        'buttons': build_buttons(message)
      }
    }

    data = build_buttons_header(message, data)
    build_footer(message, data)
  end

  private

  def build_buttons(message)
    message.content_attributes['message_payload']['content']['buttons'].map do |item|
      {
        'type': 'reply',
        'reply': {
          'id': "#{item['content']['title']}",
          'title': "#{item['content']['title'].truncate(20, :omission => '')}"
        }
      }
    end
  end

  def build_buttons_header(message, data)
    image = message.content_attributes.dig('message_payload', 'content', 'image')
    video = message.content_attributes.dig('message_payload', 'content', 'video')
    document = message.content_attributes.dig('message_payload', 'content', 'document')
    header = message.content_attributes.dig('message_payload', 'content', 'header')

    if image.present?
      return build_image_header(image, data)
    elsif video.present?
      return build_video_header(video, data)  
    elsif document.present?
      document_name = message.content_attributes.dig('message_payload', 'content', 'document_name')
      return build_document_header(document, document_name, data)
    elsif header.present?
      return build_text_header(header, data)
    else
      data
    end
  end
end
