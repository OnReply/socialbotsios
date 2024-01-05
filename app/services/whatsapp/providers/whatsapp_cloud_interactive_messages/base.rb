module Whatsapp::Providers::WhatsappCloudInteractiveMessages::Base
  def build_image_header(image, data)
    if image.present?
      data.merge({
                   'header': {
                     'type': 'image',
                     'image': { 'link': image }
                   }
                 })
    else
      data
    end
  end

  def build_video_header(video, data)
    if video.present?
      data.merge({
                   'header': {
                     'type': 'video',
                     'video': { 'link': video }
                   }
                 })
    else
      data
    end
  end

  def build_document_header(document, document_name, data)
    if document.present?
      if document_name.present?
        document_name = {'filename': document_name}
      else
        document_name = {}
      end
      data.merge({
                   'header': {
                     'type': 'document',
                     'document': { 'link': document }.merge(document_name)
                   }
                 })
    else
      data
    end
  end

  def build_text_header(header, data)
    if header.present?
      data.merge({
                   'header': {
                     'type': 'text',
                     'text': header.truncate(60, :omission => '')
                   }
                 })
    else
      data
    end
  end

  def build_footer(message, data)
    if message.content_attributes.dig('message_payload', 'content', 'footer').present?
      data = data.merge({ 'footer': { 'text': message.content_attributes.dig('message_payload', 'content', 'footer').truncate(60,
                                                                                                                              :omission => '') } })
    else
      data
    end
  end
end
