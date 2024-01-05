module Whatsapp::Providers::WhatsappCloudInteractiveMessages::Products
  include Whatsapp::Providers::WhatsappCloudInteractiveMessages::Base

  def build_products_interactive_content(message)
    data = {
      'type': 'product_list',
      'body': {
        'text': "#{message.content}"
      },
      'header': {
        'type': "text",
        'text': message.content_attributes['header']
      },
      'action': {
        'catalog_id': message.content_attributes['catalog_id'],
        'sections': build_products_sections(message)
      }
    }

    build_products_footer(message, data)
  end

  private
  
  def build_products_footer(message, data)
    footer = message.content_attributes.dig('footer')

    if footer.present?
      data = data.merge({ 'footer': { 'text': footer.truncate(60, :omission => '') } })
    else
      data
    end
  end

  def build_products_sections(message)
    message.content_attributes['products'].map { | product_list |
      { 'title': product_list['section_title'],
        'product_items': product_list['skus'].map { |sku| {'product_retailer_id': sku} }
      }
    }
  end
end
