require 'rails_helper'

describe Whatsapp::SendOnWhatsappService do
  before do
    stub_request(:post, 'https://waba.360dialog.io/v1/configs/webhook')
    # to handle the case of 24 hour window limit.
    create(:message, message_type: :incoming, content: 'test',
                     conversation: conversation)
  end

  describe '#perform' do
    let(:response_headers) { { 'Content-Type' => 'application/json' } }
    let(:whatsapp_response) { { messages: [{ id: '123456789' }] } }

    context 'when a valid message with in 24 hour limit calls' do
      let(:whatsapp_request) { double }
      let!(:whatsapp_channel) { create(:channel_whatsapp, sync_templates: false) }
      let!(:contact_inbox) { create(:contact_inbox, inbox: whatsapp_channel.inbox, source_id: '123456789') }
      let!(:conversation) { create(:conversation, contact_inbox: contact_inbox, inbox: whatsapp_channel.inbox) }

      it 'calls message endpoints for products messages' do
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
                    inbox: whatsapp_channel.inbox,
                    conversation: conversation
        )

        stub_request(:post, 'https://waba.360dialog.io/v1/messages')
          .with(
            body: {"messaging_product":"whatsapp","to":"123456789","interactive":{"type":"product_list","body":{"text":"test"},"header":{"type":"text","text":"product header"},"action":{"catalog_id":"1183719818989019","sections":[{"title":"section title","product_items":[{"product_retailer_id":"5r4tap9sy6"}]}]}},"type":"interactive"}.to_json
          )
          .to_return(status: 200, body: whatsapp_response.to_json, headers: response_headers)

        described_class.new(message: message).perform
        expect(message.reload.source_id).to eq('123456789')
      end
    end
  end
end
