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

      it 'calls message endpoints for interactive list buttons messages' do
        message = create(:message, message_type: :outgoing, content: 'test',
                                   conversation: conversation, content_type: 'input_select',
                                   content_attributes: {
                                     'items' => [{ 'title' => 'test', 'value' => 'test' }, { 'title' => 'test 2', 'value' => 'test 2' },
                                                 { 'title' => 'test 3', 'value' => 'test 3' }, { 'title' => 'test 4', 'value' => 'test 4' }],
                                     'message_payload' => { 'content_type' => 'question',
                                                            'content' =>
                                       { 'style' => 'primary',
                                         'buttons' =>
                                         [
                                           {
                                             'content_type' => 'button',
                                             'content' => { 'title' => 'test', 'accepts' => ['teste'] }
                                           },
                                           {
                                             'content_type' => 'button',
                                             'content' => { 'title' => 'test 2', 'accepts' => ['test 2'] }
                                           },
                                           {
                                             'content_type' => 'button',
                                             'content' => { 'title' => 'test 3', 'accepts' => ['test 3'] }
                                           },
                                           {
                                             'content_type' => 'button',
                                             'content' => { 'title' => 'test 4', 'accepts' => ['test 4'] }
                                           }
                                         ],
                                         'title' => 'What would you like to do today?' } }
                                   })

        stub_request(:post, 'https://waba.360dialog.io/v1/messages')
          .with(
            body: '{"messaging_product":"whatsapp","to":"123456789","interactive":{"type":"list","body":{"text":"test"},"action":{"button":"Select","sections":[{"title":"Options","rows":[{"id":"test","title":"test"},{"id":"test 2","title":"test 2"},{"id":"test 3","title":"test 3"},{"id":"test 4","title":"test 4"}]}]}},"type":"interactive"}'
          )
          .to_return(status: 200, body: whatsapp_response.to_json, headers: response_headers)

        described_class.new(message: message).perform
        expect(message.reload.source_id).to eq('123456789')
      end

      it 'ccalls message endpoints for interactive list buttons messages with custom action button' do
        message = create(:message, message_type: :outgoing, content: 'test',
                                   conversation: conversation, content_type: 'input_select',
                                   content_attributes: {
                                     'items' => [{ 'title' => 'test', 'value' => 'test' }, { 'title' => 'test 2', 'value' => 'test 2' },
                                                 { 'title' => 'test 3', 'value' => 'test 3' }, { 'title' => 'test 4', 'value' => 'test 4' }],
                                     'message_payload' => { 'content_type' => 'question',
                                                            'content' =>
              { 'style' => 'primary',
                'action_button' => 'testing..',
                'buttons' =>
                [
                  {
                    'content_type' => 'button',
                    'content' => { 'title' => 'test', 'accepts' => ['teste'] }
                  },
                  {
                    'content_type' => 'button',
                    'content' => { 'title' => 'test 2', 'accepts' => ['test 2'] }
                  },
                  {
                    'content_type' => 'button',
                    'content' => { 'title' => 'test 3', 'accepts' => ['test 3'] }
                  },
                  {
                    'content_type' => 'button',
                    'content' => { 'title' => 'test 4', 'accepts' => ['test 4'] }
                  }
                ],
                'title' => 'What would you like to do today?' } }
                                   })

        stub_request(:post, 'https://waba.360dialog.io/v1/messages')
          .with(
            body: '{"messaging_product":"whatsapp","to":"123456789","interactive":{"type":"list","body":{"text":"test"},"action":{"button":"testing..","sections":[{"title":"Options","rows":[{"id":"test","title":"test"},{"id":"test 2","title":"test 2"},{"id":"test 3","title":"test 3"},{"id":"test 4","title":"test 4"}]}]}},"type":"interactive"}'
          )
          .to_return(status: 200, body: whatsapp_response.to_json, headers: response_headers)

        described_class.new(message: message).perform
        expect(message.reload.source_id).to eq('123456789')
      end

      it 'calls message endpoints for interactive list buttons messages with large custom action button' do
        message = create(:message, message_type: :outgoing, content: 'test',
                                   conversation: conversation, content_type: 'input_select',
                                   content_attributes: {
                                     'items' => [{ 'title' => 'test', 'value' => 'test' }, { 'title' => 'test 2', 'value' => 'test 2' },
                                                 { 'title' => 'test 3', 'value' => 'test 3' }, { 'title' => 'test 4', 'value' => 'test 4' }],
                                     'message_payload' => { 'content_type' => 'question',
                                                            'content' =>
              { 'style' => 'primary',
                'action_button' => 'testing29chars...............',
                'buttons' =>
                [
                  {
                    'content_type' => 'button',
                    'content' => { 'title' => 'test', 'accepts' => ['teste'] }
                  },
                  {
                    'content_type' => 'button',
                    'content' => { 'title' => 'test 2', 'accepts' => ['test 2'] }
                  },
                  {
                    'content_type' => 'button',
                    'content' => { 'title' => 'test 3', 'accepts' => ['test 3'] }
                  },
                  {
                    'content_type' => 'button',
                    'content' => { 'title' => 'test 4', 'accepts' => ['test 4'] }
                  }
                ],
                'title' => 'What would you like to do today?' } }
                                   })

        stub_request(:post, 'https://waba.360dialog.io/v1/messages')
          .with(
            body: '{"messaging_product":"whatsapp","to":"123456789","interactive":{"type":"list","body":{"text":"test"},"action":{"button":"testing29chars......","sections":[{"title":"Options","rows":[{"id":"test","title":"test"},{"id":"test 2","title":"test 2"},{"id":"test 3","title":"test 3"},{"id":"test 4","title":"test 4"}]}]}},"type":"interactive"}'
          )
          .to_return(status: 200, body: whatsapp_response.to_json, headers: response_headers)

        described_class.new(message: message).perform
        expect(message.reload.source_id).to eq('123456789')
      end

      it 'calls message endpoints for interactive list buttons messages with header' do
        message = create(:message, message_type: :outgoing, content: 'test',
                                   conversation: conversation, content_type: 'input_select',
                                   content_attributes: {
                                     'items' => [{ 'title' => 'test', 'value' => 'test' }, { 'title' => 'test 2', 'value' => 'test 2' },
                                                 { 'title' => 'test 3', 'value' => 'test 3' }, { 'title' => 'test 4', 'value' => 'test 4' }],
                                     'message_payload' => { 'content_type' => 'question',
                                                            'content' =>
              { 'style' => 'primary',
                'header' => 'testing29chars...............',
                'buttons' =>
                [
                  {
                    'content_type' => 'button',
                    'content' => { 'title' => 'test', 'accepts' => ['teste'] }
                  },
                  {
                    'content_type' => 'button',
                    'content' => { 'title' => 'test 2', 'accepts' => ['test 2'] }
                  },
                  {
                    'content_type' => 'button',
                    'content' => { 'title' => 'test 3', 'accepts' => ['test 3'] }
                  },
                  {
                    'content_type' => 'button',
                    'content' => { 'title' => 'test 4', 'accepts' => ['test 4'] }
                  }
                ],
                'title' => 'What would you like to do today?' } }
                                   })

        stub_request(:post, 'https://waba.360dialog.io/v1/messages')
          .with(
            body: '{"messaging_product":"whatsapp","to":"123456789","interactive":{"type":"list","body":{"text":"test"},"action":{"button":"Select","sections":[{"title":"Options","rows":[{"id":"test","title":"test"},{"id":"test 2","title":"test 2"},{"id":"test 3","title":"test 3"},{"id":"test 4","title":"test 4"}]}]},"header":{"type":"text","text":"testing29chars..............."}},"type":"interactive"}'
          )
          .to_return(status: 200, body: whatsapp_response.to_json, headers: response_headers)

        described_class.new(message: message).perform
        expect(message.reload.source_id).to eq('123456789')
      end

      it 'calls message endpoints for interactive list buttons messages with footer' do
        message = create(:message, message_type: :outgoing, content: 'test',
                                   conversation: conversation, content_type: 'input_select',
                                   content_attributes: {
                                     'items' => [{ 'title' => 'test', 'value' => 'test' }, { 'title' => 'test 2', 'value' => 'test 2' },
                                                 { 'title' => 'test 3', 'value' => 'test 3' }, { 'title' => 'test 4', 'value' => 'test 4' }],
                                     'message_payload' => { 'content_type' => 'question',
                                                            'content' =>
              { 'style' => 'primary',
                'footer' => 'testing29chars...............',
                'buttons' =>
                [
                  {
                    'content_type' => 'button',
                    'content' => { 'title' => 'test', 'accepts' => ['teste'] }
                  },
                  {
                    'content_type' => 'button',
                    'content' => { 'title' => 'test 2', 'accepts' => ['test 2'] }
                  },
                  {
                    'content_type' => 'button',
                    'content' => { 'title' => 'test 3', 'accepts' => ['test 3'] }
                  },
                  {
                    'content_type' => 'button',
                    'content' => { 'title' => 'test 4', 'accepts' => ['test 4'] }
                  }
                ],
                'title' => 'What would you like to do today?' } }
                                   })

        stub_request(:post, 'https://waba.360dialog.io/v1/messages')
          .with(
            body: '{"messaging_product":"whatsapp","to":"123456789","interactive":{"type":"list","body":{"text":"test"},"action":{"button":"Select","sections":[{"title":"Options","rows":[{"id":"test","title":"test"},{"id":"test 2","title":"test 2"},{"id":"test 3","title":"test 3"},{"id":"test 4","title":"test 4"}]}]},"footer":{"text":"testing29chars..............."}},"type":"interactive"}'
          )
          .to_return(status: 200, body: whatsapp_response.to_json, headers: response_headers)

        described_class.new(message: message).perform
        expect(message.reload.source_id).to eq('123456789')
      end

      it 'calls message endpoints for interactive list buttons messages with description' do
        message = create(:message, message_type: :outgoing, content: 'test',
                                   conversation: conversation, content_type: 'input_select',
                                   content_attributes: {
                                     'items' => [{ 'title' => 'test', 'value' => 'test' }, { 'title' => 'test 2', 'value' => 'test 2' },
                                                 { 'title' => 'test 3', 'value' => 'test 3' }, { 'title' => 'test 4', 'value' => 'test 4' }],
                                     'message_payload' => { 'content_type' => 'question',
                                                            'content' =>
              { 'style' => 'primary',
                'footer' => 'testing29chars...............',
                'buttons' =>
                [
                  {
                    'content_type' => 'button',
                    'content' => { 'title' => 'test', 'accepts' => ['teste'], 'description' => 'Description 1' }
                  },
                  {
                    'content_type' => 'button',
                    'content' => { 'title' => 'test 2', 'accepts' => ['test 2'] }
                  },
                  {
                    'content_type' => 'button',
                    'content' => { 'title' => 'test 3', 'accepts' => ['test 3'] }
                  },
                  {
                    'content_type' => 'button',
                    'content' => { 'title' => 'test 4', 'accepts' => ['test 4'] }
                  }
                ],
                'title' => 'What would you like to do today?' } }
                                   })

        stub_request(:post, 'https://waba.360dialog.io/v1/messages')
          .with(
            body: '{"messaging_product":"whatsapp","to":"123456789","interactive":{"type":"list","body":{"text":"test"},"action":{"button":"Select","sections":[{"title":"Options","rows":[{"id":"test","title":"test","description":"Description 1"},{"id":"test 2","title":"test 2"},{"id":"test 3","title":"test 3"},{"id":"test 4","title":"test 4"}]}]},"footer":{"text":"testing29chars..............."}},"type":"interactive"}'
          )
          .to_return(status: 200, body: whatsapp_response.to_json, headers: response_headers)

        described_class.new(message: message).perform
        expect(message.reload.source_id).to eq('123456789')
      end

      it 'calls message endpoints for interactive list buttons messages with one button has a section and others without' do
        message = create(:message, message_type: :outgoing, content: 'test',
                                   conversation: conversation, content_type: 'input_select',
                                   content_attributes: {
                                     'items' => [{ 'title' => 'test', 'value' => 'test' }, { 'title' => 'test 2', 'value' => 'test 2' },
                                                 { 'title' => 'test 3', 'value' => 'test 3' }, { 'title' => 'test 4', 'value' => 'test 4' }],
                                     'message_payload' => { 'content_type' => 'question',
                                                            'content' =>
              { 'style' => 'primary',
                'footer' => 'testing29chars...............',
                'buttons' =>
                [
                  {
                    'content_type' => 'button',
                    'content' => { 'title' => 'test', 'accepts' => ['teste'], 'section_title' => 'Section 1' }
                  },
                  {
                    'content_type' => 'button',
                    'content' => { 'title' => 'test 2', 'accepts' => ['test 2'] }
                  },
                  {
                    'content_type' => 'button',
                    'content' => { 'title' => 'test 3', 'accepts' => ['test 3'] }
                  },
                  {
                    'content_type' => 'button',
                    'content' => { 'title' => 'test 4', 'accepts' => ['test 4'] }
                  }
                ],
                'title' => 'What would you like to do today?' } }
                                   })

        stub_request(:post, 'https://waba.360dialog.io/v1/messages')
          .with(
            body: '{"messaging_product":"whatsapp","to":"123456789","interactive":{"type":"list","body":{"text":"test"},"action":{"button":"Select","sections":[{"title":"Section 1","rows":[{"id":"test","title":"test"}]},{"title":"Options","rows":[{"id":"test 2","title":"test 2"},{"id":"test 3","title":"test 3"},{"id":"test 4","title":"test 4"}]}]},"footer":{"text":"testing29chars..............."}},"type":"interactive"}'
          )
          .to_return(status: 200, body: whatsapp_response.to_json, headers: response_headers)

        described_class.new(message: message).perform
        expect(message.reload.source_id).to eq('123456789')
      end

      it 'calls message endpoints for interactive list buttons messages with one section' do
        message = create(:message, message_type: :outgoing, content: 'test',
                                   conversation: conversation, content_type: 'input_select',
                                   content_attributes: {
                                     'items' => [{ 'title' => 'test', 'value' => 'test' }, { 'title' => 'test 2', 'value' => 'test 2' },
                                                 { 'title' => 'test 3', 'value' => 'test 3' }, { 'title' => 'test 4', 'value' => 'test 4' }],
                                     'message_payload' => { 'content_type' => 'question',
                                                            'content' =>
              { 'style' => 'primary',
                'footer' => 'testing29chars...............',
                'buttons' =>
                [
                  {
                    'content_type' => 'button',
                    'content' => { 'title' => 'test', 'accepts' => ['teste'], 'section_title' => 'Section 1' }
                  },
                  {
                    'content_type' => 'button',
                    'content' => { 'title' => 'test 2', 'accepts' => ['test 2'], 'section_title' => 'Section 1' }
                  },
                  {
                    'content_type' => 'button',
                    'content' => { 'title' => 'test 3', 'accepts' => ['test 3'], 'section_title' => 'Section 1' }
                  },
                  {
                    'content_type' => 'button',
                    'content' => { 'title' => 'test 4', 'accepts' => ['test 4'], 'section_title' => 'Section 1' }
                  }
                ],
                'title' => 'What would you like to do today?' } }
                                   })

        stub_request(:post, 'https://waba.360dialog.io/v1/messages')
          .with(
            body: '{"messaging_product":"whatsapp","to":"123456789","interactive":{"type":"list","body":{"text":"test"},"action":{"button":"Select","sections":[{"title":"Section 1","rows":[{"id":"test","title":"test"},{"id":"test 2","title":"test 2"},{"id":"test 3","title":"test 3"},{"id":"test 4","title":"test 4"}]}]},"footer":{"text":"testing29chars..............."}},"type":"interactive"}'
          )
          .to_return(status: 200, body: whatsapp_response.to_json, headers: response_headers)

        described_class.new(message: message).perform
      end

      it 'calls message endpoints for interactive list buttons messages with two sections' do
        message = create(:message, message_type: :outgoing, content: 'test',
                                   conversation: conversation, content_type: 'input_select',
                                   content_attributes: {
                                     'items' => [{ 'title' => 'test', 'value' => 'test' }, { 'title' => 'test 2', 'value' => 'test 2' },
                                                 { 'title' => 'test 3', 'value' => 'test 3' }, { 'title' => 'test 4', 'value' => 'test 4' }],
                                     'message_payload' => { 'content_type' => 'question',
                                                            'content' =>
              { 'style' => 'primary',
                'footer' => 'testing29chars...............',
                'buttons' =>
                [
                  {
                    'content_type' => 'button',
                    'content' => { 'title' => 'test', 'accepts' => ['teste'], 'section_title' => 'Section 1' }
                  },
                  {
                    'content_type' => 'button',
                    'content' => { 'title' => 'test 2', 'accepts' => ['test 2'], 'section_title' => 'Section 1' }
                  },
                  {
                    'content_type' => 'button',
                    'content' => { 'title' => 'test 3', 'accepts' => ['test 3'], 'section_title' => 'Section 2' }
                  },
                  {
                    'content_type' => 'button',
                    'content' => { 'title' => 'test 4', 'accepts' => ['test 4'], 'section_title' => 'Section 2' }
                  }
                ],
                'title' => 'What would you like to do today?' } }
                                   })

        stub_request(:post, 'https://waba.360dialog.io/v1/messages')
          .with(
            body: '{"messaging_product":"whatsapp","to":"123456789","interactive":{"type":"list","body":{"text":"test"},"action":{"button":"Select","sections":[{"title":"Section 1","rows":[{"id":"test","title":"test"},{"id":"test 2","title":"test 2"}]},{"title":"Section 2","rows":[{"id":"test 3","title":"test 3"},{"id":"test 4","title":"test 4"}]}]},"footer":{"text":"testing29chars..............."}},"type":"interactive"}'
          )
          .to_return(status: 200, body: whatsapp_response.to_json, headers: response_headers)

        described_class.new(message: message).perform
        expect(message.reload.source_id).to eq('123456789')
      end
    end
  end
end
