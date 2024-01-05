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

      it 'calls message endpoints for interactive quick buttons messages' do
        message = create(:message, message_type: :outgoing, content: 'test',
                                   conversation: conversation, content_type: 'input_select',
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
                                   })

        stub_request(:post, 'https://waba.360dialog.io/v1/messages')
          .with(
            body: '{"messaging_product":"whatsapp","to":"123456789","interactive":{"type":"button","body":{"text":"test"},"action":{"buttons":[{"type":"reply","reply":{"id":"test","title":"test"}}]}},"type":"interactive"}'
          )
          .to_return(status: 200, body: whatsapp_response.to_json, headers: response_headers)

        described_class.new(message: message).perform
        expect(message.reload.source_id).to eq('123456789')
      end

      it 'calls message endpoints for interactive quick buttons messages with image' do
        message = create(
          :message, message_type: :outgoing, content: 'test', content_type: 'input_select', conversation: conversation,
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

        stub_request(:post, 'https://waba.360dialog.io/v1/messages')
          .with(
            body: {
              messaging_product: 'whatsapp',
              to: '123456789',
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

        described_class.new(message: message).perform
        expect(message.reload.source_id).to eq('123456789')
      end

      it 'calls message endpoints for interactive quick buttons messages with video' do
        message = create(
          :message, message_type: :outgoing, content: 'test', content_type: 'input_select', conversation: conversation,
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

        stub_request(:post, 'https://waba.360dialog.io/v1/messages')
          .with(
            body: {
              messaging_product: 'whatsapp',
              to: '123456789',
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

        described_class.new(message: message).perform
        expect(message.reload.source_id).to eq('123456789')
      end

      it 'calls message endpoints for interactive quick buttons messages with document' do
        message = create(
          :message, message_type: :outgoing, content: 'test', content_type: 'input_select', conversation: conversation,
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

        stub_request(:post, 'https://waba.360dialog.io/v1/messages')
          .with(
            body: {
              messaging_product: 'whatsapp',
              to: '123456789',
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

        described_class.new(message: message).perform
        expect(message.reload.source_id).to eq('123456789')
      end

      it 'calls message endpoints for interactive quick buttons messages with document and document name' do
        message = create(
          :message, message_type: :outgoing, content: 'test', content_type: 'input_select', conversation: conversation,
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

        stub_request(:post, 'https://waba.360dialog.io/v1/messages')
          .with(
            body: {
              messaging_product: 'whatsapp',
              to: '123456789',
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

        described_class.new(message: message).perform
        expect(message.reload.source_id).to eq('123456789')
      end
    end
  end
end
