require 'rails_helper'

describe Whatsapp::Providers::WhatsappCloudService do
  subject(:service) { described_class.new(whatsapp_channel: whatsapp_channel) }

  let(:whatsapp_channel) { create(:channel_whatsapp, provider: 'whatsapp_cloud', validate_provider_config: false, sync_templates: false) }
  let(:response_headers) { { 'Content-Type' => 'application/json' } }
  let(:whatsapp_response) { { messages: [{ id: 'message_id' }] } }

  describe '#send_message' do
    context 'when called' do
      context 'products' do
        it 'calls message endpoints for products messages' do
          stub_request(:get, /oauth\/access_token/).
          to_return(status: 200, body: {"access_token": "1234", expires_in: Time.current.to_i }.to_json, headers: response_headers)
 
          stub_request(:get, /debug_token/).
          to_return(status: 200, body: {'data': {'expires_at': (Time.current + 10.days).to_i}}.to_json, headers: response_headers)
 
          stub_request(:get, "https://graph.facebook.com/v16.0/123456789/subscribed_apps").
          to_return(status: 200, body: {"data": [{"whatsapp_business_api_data": {"link": "https://www.facebook.com/games/?app_id=742189254309938","name": "Baggio - 41998154704","id": "742189254309938"}}]}.to_json, headers: response_headers)

          message = create(
            :message, message_type: :outgoing, content: 'test', content_type: 'integrations',
                      content_attributes: {
                        'type': 'whatsappproducts',
                        'products': [
                          {'section_title': 'section title', 'skus': ['5r4tap9sy6']}
                        ],
                        'header': 'product header',
                        'catalog_id': '1183719818989019',
                        'message_payload' => {"content_type"=>"Component.whatsappproducts", "content"=>{"skus"=>["sku1", "sku2"]}}
                      },
                      inbox: whatsapp_channel.inbox
          )

          stub_request(:post, /messages/)
            .with(
              body: {"messaging_product":"whatsapp","to":"+123456789","interactive":{"type":"product_list","body":{"text":"test"},"header": {"type": "text", "text": "product header"},"action":{"catalog_id":"1183719818989019","sections":[{"title":"section title","product_items":[{"product_retailer_id":"5r4tap9sy6"}]}]}},"type":"interactive"}.to_json
            )
            .to_return(status: 200, body: whatsapp_response.to_json, headers: response_headers)
          expect(service.send_message('+123456789', message)).to eq 'message_id'
        end
      end
    end
  end
end
