require 'rails_helper'

describe Whatsapp::Providers::WhatsappCloudService do
  subject(:service) { described_class.new(whatsapp_channel: whatsapp_channel) }

  let(:whatsapp_channel) { create(:channel_whatsapp, provider: 'whatsapp_cloud', validate_provider_config: false, sync_templates: false) }
  let(:response_headers) { { 'Content-Type' => 'application/json' } }
  let(:whatsapp_response) { { messages: [{ id: 'message_id' }] } }

  describe '#send_message' do
    context 'when called' do
      it 'calls message endpoints for interactive quick buttons messages' do
        stub_request(:get, %r{oauth/access_token})
          .to_return(status: 200, body: { 'access_token': '1234', expires_in: Time.current.to_i }.to_json, headers: response_headers)

        stub_request(:get, /debug_token/)
          .to_return(status: 200, body: { 'data': { 'expires_at': 10.days.from_now.to_i } }.to_json, headers: response_headers)
        message = create(
          :message, message_type: :outgoing, content: 'test', content_type: 'input_select',
                    content_attributes: {
                      'items' => [{ 'title' => 'test', 'value' => 'test' }],
                      'message_payload' => { 'content_type' => 'question',
                                             'content' =>
                         { 'style' => 'primary',
                           'buttons' =>
                           [
                             { 'content_type' => 'button',
                               'content' => { 'title' => 'test', 'accepts' => ['teste'] } }
                           ],
                           'title' => 'What would you like to do today?' } }
                    },
                    inbox: whatsapp_channel.inbox
        )

        stub_request(:post, 'https://graph.facebook.com/v13.0/123456789/messages')
          .with(
            body: {
              messaging_product: 'whatsapp',
              to: '+123456789',
              interactive: {
                type: 'button',
                body: { text: 'test' },
                action: {
                  buttons: [{ type: 'reply', reply: { id: 'test', title: 'test' } }]
                }
              },
              type: 'interactive'
            }.to_json
          )
          .to_return(status: 200, body: whatsapp_response.to_json, headers: response_headers)
        expect(service.send_message('+123456789', message)).to eq 'message_id'
      end

      it 'calls message endpoints for interactive quick buttons messages with image' do
        stub_request(:get, %r{oauth/access_token})
          .to_return(status: 200, body: { 'access_token': '1234', expires_in: Time.current.to_i }.to_json, headers: response_headers)

        stub_request(:get, /debug_token/)
          .to_return(status: 200, body: { 'data': { 'expires_at': 10.days.from_now.to_i } }.to_json, headers: response_headers)
        message = create(
          :message, message_type: :outgoing, content: 'test', content_type: 'input_select',
                    content_attributes: {
                      'items' => [{ 'title' => 'test', 'value' => 'test' }],
                      'message_payload' => { 'content_type' => 'question',
                                             'content' =>
                         { 'image' => 'https://media4.giphy.com/media/dzaUX7CAG0Ihi/giphy.gif',
                           'buttons' =>
                           [
                             { 'content_type' => 'button',
                               'content' => { 'title' => 'test', 'accepts' => ['teste'] } }
                           ],
                           'title' => 'What would you like to do today?' } }
                    },
                    inbox: whatsapp_channel.inbox
        )

        stub_request(:post, 'https://graph.facebook.com/v13.0/123456789/messages')
          .with(
            body: {
              messaging_product: 'whatsapp',
              to: '+123456789',
              interactive: {
                type: 'button',
                body: { text: 'test' },
                action: {
                  buttons: [{ type: 'reply', reply: { id: 'test', title: 'test' } }]
                },
                header: { type: 'image', image: { link: 'https://media4.giphy.com/media/dzaUX7CAG0Ihi/giphy.gif' } }
              },
              type: 'interactive'
            }.to_json
          )
          .to_return(status: 200, body: whatsapp_response.to_json, headers: response_headers)
        expect(service.send_message('+123456789', message)).to eq 'message_id'
      end

      it 'calls message endpoints for interactive quick buttons messages with video' do
        stub_request(:get, %r{oauth/access_token})
          .to_return(status: 200, body: { 'access_token': '1234', expires_in: Time.current.to_i }.to_json, headers: response_headers)

        stub_request(:get, /debug_token/)
          .to_return(status: 200, body: { 'data': { 'expires_at': 10.days.from_now.to_i } }.to_json, headers: response_headers)
        message = create(
          :message, message_type: :outgoing, content: 'test', content_type: 'input_select',
                    content_attributes: {
                      'items' => [{ 'title' => 'test', 'value' => 'test' }],
                      'message_payload' => { 'content_type' => 'question',
                                             'content' =>
                         { 'video' => 'https://media.giphy.com/media/3oKIPsx2VAYAgEHC12/giphy.mp4',
                           'buttons' =>
                           [
                             { 'content_type' => 'button',
                               'content' => { 'title' => 'test', 'accepts' => ['teste'] } }
                           ],
                           'title' => 'What would you like to do today?' } }
                    },
                    inbox: whatsapp_channel.inbox
        )

        stub_request(:post, 'https://graph.facebook.com/v13.0/123456789/messages')
          .with(
            body: {
              messaging_product: 'whatsapp',
              to: '+123456789',
              interactive: {
                type: 'button',
                body: { text: 'test' },
                action: {
                  buttons: [{ type: 'reply', reply: { id: 'test', title: 'test' } }]
                },
                header: { type: 'video', video: { link: 'https://media.giphy.com/media/3oKIPsx2VAYAgEHC12/giphy.mp4' } }
              },
              type: 'interactive'
            }.to_json
          )
          .to_return(status: 200, body: whatsapp_response.to_json, headers: response_headers)
        expect(service.send_message('+123456789', message)).to eq 'message_id'
      end

      it 'calls message endpoints for interactive quick buttons messages with document' do
        stub_request(:get, %r{oauth/access_token})
          .to_return(status: 200, body: { 'access_token': '1234', expires_in: Time.current.to_i }.to_json, headers: response_headers)

        stub_request(:get, /debug_token/)
          .to_return(status: 200, body: { 'data': { 'expires_at': 10.days.from_now.to_i } }.to_json, headers: response_headers)
        message = create(
          :message, message_type: :outgoing, content: 'test', content_type: 'input_select',
                    content_attributes: {
                      'items' => [{ 'title' => 'test', 'value' => 'test' }],
                      'message_payload' => { 'content_type' => 'question',
                                             'content' =>
                         { 'document' => 'https://nyphil.org/~/media/pdfs/program-notes/1819/Brahms-Symphony-No-4.pdf',
                           'buttons' =>
                           [
                             { 'content_type' => 'button',
                               'content' => { 'title' => 'test', 'accepts' => ['teste'] } }
                           ],
                           'title' => 'What would you like to do today?' } }
                    },
                    inbox: whatsapp_channel.inbox
        )

        stub_request(:post, 'https://graph.facebook.com/v13.0/123456789/messages')
          .with(
            body: {
              messaging_product: 'whatsapp',
              to: '+123456789',
              interactive: {
                type: 'button',
                body: { text: 'test' },
                action: {
                  buttons: [{ type: 'reply', reply: { id: 'test', title: 'test' } }]
                },
                header: { type: 'document', document: { link: 'https://nyphil.org/~/media/pdfs/program-notes/1819/Brahms-Symphony-No-4.pdf' } }
              },
              type: 'interactive'
            }.to_json
          )
          .to_return(status: 200, body: whatsapp_response.to_json, headers: response_headers)
        expect(service.send_message('+123456789', message)).to eq 'message_id'
      end

      it 'calls message endpoints for interactive quick buttons messages with document and document name' do
        stub_request(:get, %r{oauth/access_token})
          .to_return(status: 200, body: { 'access_token': '1234', expires_in: Time.current.to_i }.to_json, headers: response_headers)

        stub_request(:get, /debug_token/)
          .to_return(status: 200, body: { 'data': { 'expires_at': 10.days.from_now.to_i } }.to_json, headers: response_headers)
        message = create(
          :message, message_type: :outgoing, content: 'test', content_type: 'input_select',
                    content_attributes: {
                      'items' => [{ 'title' => 'test', 'value' => 'test' }],
                      'message_payload' => { 'content_type' => 'question',
                                             'content' =>
                         { 'document' => 'https://nyphil.org/~/media/pdfs/program-notes/1819/Brahms-Symphony-No-4.pdf',
                           'document_name' => 'file_example.pdf',
                           'buttons' =>
                           [
                             { 'content_type' => 'button',
                               'content' => { 'title' => 'test', 'accepts' => ['teste'] } }
                           ],
                           'title' => 'What would you like to do today?' } }
                    },
                    inbox: whatsapp_channel.inbox
        )

        stub_request(:post, 'https://graph.facebook.com/v13.0/123456789/messages')
          .with(
            body: {
              messaging_product: 'whatsapp',
              to: '+123456789',
              interactive: {
                type: 'button',
                body: { text: 'test' },
                action: {
                  buttons: [{ type: 'reply', reply: { id: 'test', title: 'test' } }]
                },
                header: { type: 'document', document: { link: 'https://nyphil.org/~/media/pdfs/program-notes/1819/Brahms-Symphony-No-4.pdf', 'filename': 'file_example.pdf' } }
              },
              type: 'interactive'
            }.to_json
          )
          .to_return(status: 200, body: whatsapp_response.to_json, headers: response_headers)
        expect(service.send_message('+123456789', message)).to eq 'message_id'
      end
    end
  end
end
