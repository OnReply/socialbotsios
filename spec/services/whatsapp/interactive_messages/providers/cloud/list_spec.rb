require 'rails_helper'

describe Whatsapp::Providers::WhatsappCloudService do
  subject(:service) { described_class.new(whatsapp_channel: whatsapp_channel) }

  let(:whatsapp_channel) { create(:channel_whatsapp, provider: 'whatsapp_cloud', validate_provider_config: false, sync_templates: false) }
  let(:response_headers) { { 'Content-Type' => 'application/json' } }
  let(:whatsapp_response) { { messages: [{ id: 'message_id' }] } }

  describe '#send_message' do
    context 'when called' do
      context 'list' do
        it 'calls message endpoints for interactive list buttons messages' do
          stub_request(:get, /oauth\/access_token/).
          to_return(status: 200, body: {"access_token": "1234", expires_in: Time.current.to_i }.to_json, headers: response_headers)
 
          stub_request(:get, /debug_token/).
          to_return(status: 200, body: {'data': {'expires_at': (Time.current + 10.days).to_i}}.to_json, headers: response_headers)
 
          message = create(
            :message, message_type: :outgoing, content: 'test', content_type: 'input_select',
                      content_attributes: { 
                        'items' => [{ 'title' => 'test', 'value' => 'test' }, { 'title' => 'test 2', 'value' => 'test 2' }, { 'title' => 'test 3', 'value' => 'test 3'}, { 'title' => 'test 4', 'value' => 'test 4' } ],
                        'message_payload' => {"content_type"=>"question",
                          "content"=>
                           {"style"=>"primary",
                            "buttons"=>
                             [
                                { 
                                  "content_type"=>"button",
                                  "content"=>{ "title"=>"test","accepts"=>["teste"]}
                                },
                                { 
                                  "content_type"=>"button",
                                  "content"=>{ "title"=>"test 2","accepts"=>["test 2"]}
                                },
                                { 
                                  "content_type"=>"button",
                                  "content"=>{ "title"=>"test 3","accepts"=>["test 3"]}
                                },
                                { 
                                  "content_type"=>"button",
                                  "content"=>{ "title"=>"test 4","accepts"=>["test 4"]}
                                }
                              ],
                            "title"=>"What would you like to do today?"}}
                      },
                      inbox: whatsapp_channel.inbox
          )

          stub_request(:post, 'https://graph.facebook.com/v13.0/123456789/messages')
            .with(
              body: {
                messaging_product: 'whatsapp',
                to: '+123456789',
                interactive: {
                  type: "list", body: {:text=>"test"},
                  action: { button: "Select", sections: [{title: "Options", rows: [{id: "test", title: "test"}, {id: "test 2", title: "test 2"}, {id: "test 3", title: "test 3"}, {id: "test 4", title: "test 4"}]}]}
                },
                type: "interactive"
              }.to_json
            )
            .to_return(status: 200, body: whatsapp_response.to_json, headers: response_headers)
          expect(service.send_message('+123456789', message)).to eq 'message_id'
        end

        it 'calls message endpoints for interactive list buttons messages with custom action button' do
          stub_request(:get, /oauth\/access_token/).
          to_return(status: 200, body: {"access_token": "1234", expires_in: Time.current.to_i }.to_json, headers: response_headers)
 
          stub_request(:get, /debug_token/).
          to_return(status: 200, body: {'data': {'expires_at': (Time.current + 10.days).to_i}}.to_json, headers: response_headers)

          message = create(
            :message, message_type: :outgoing, content: 'test', content_type: 'input_select',
                      content_attributes: {
                        'items' => [{ 'title' => 'test', 'value' => 'test' }, { 'title' => 'test 2', 'value' => 'test 2' }, { 'title' => 'test 3', 'value' => 'test 3'}, { 'title' => 'test 4', 'value' => 'test 4' } ],
                        'message_payload' => {"content_type"=>"question",
                          "content"=>
                           {"style"=>"primary",
                            "action_button"=>"testing..",
                            "buttons"=>
                             [{"content_type"=>"button",
                               "content"=>
                                {"title"=>"Listen to good music",
                                 "accepts"=>["music", "listen", "Listen to good music", "Listen to good music"],
                                 "payload"=>"Listen to good music"}},
                              {"content_type"=>"button",
                               "content"=>
                                {"payload"=>"Manage my Dropbox account",
                                 "title"=>"Manage my Dropbox account",
                                 "accepts"=>["dropbox", "Manage my Dropbox account", "Manage my Dropbox account"]}},
                              {"content"=>{"title"=>"Tell me a joke", "accepts"=>["Tell me a joke", "Tell me a joke"], "payload"=>"Tell me a joke"},
                               "content_type"=>"button"},
                              {"content"=>{"payload"=>"123 Tell me a joke", "title"=>"123 Tell me a joke", "accepts"=>["123 Tell me a joke", "123 Tell me a joke"]},
                               "content_type"=>"button"}],
                            "title"=>"What would you like to do today?"}}
                      },
                      inbox: whatsapp_channel.inbox
          )

          stub_request(:post, 'https://graph.facebook.com/v13.0/123456789/messages')
            .with(
              body: {"messaging_product":"whatsapp","to":"+123456789","interactive":{"type":"list","body":{"text":"test"},"action":{"button":"testing..","sections":[{"title":"Options","rows":[{"id":"Listen to good music","title":"Listen to good music"},{"id":"Manage my Dropbox account","title":"Manage my Dropbox accoun"},{"id":"Tell me a joke","title":"Tell me a joke"},{"id":"123 Tell me a joke","title":"123 Tell me a joke"}]}]}},"type":"interactive"}.to_json
            )
            .to_return(status: 200, body: whatsapp_response.to_json, headers: response_headers)
          expect(service.send_message('+123456789', message)).to eq 'message_id'
        end

        it 'calls message endpoints for interactive list buttons messages with large custom action button' do
          stub_request(:get, /oauth\/access_token/).
          to_return(status: 200, body: {"access_token": "1234", expires_in: Time.current.to_i }.to_json, headers: response_headers)
 
          stub_request(:get, /debug_token/).
          to_return(status: 200, body: {'data': {'expires_at': (Time.current + 10.days).to_i}}.to_json, headers: response_headers)

          message = create(
            :message, message_type: :outgoing, content: 'test', content_type: 'input_select',
                      content_attributes: {
                        'items' => [{ 'title' => 'test', 'value' => 'test' }, { 'title' => 'test 2', 'value' => 'test 2' }, { 'title' => 'test 3', 'value' => 'test 3'}, { 'title' => 'test 4', 'value' => 'test 4' } ],
                        'message_payload' => {"content_type"=>"question",
                          "content"=>
                           {"style"=>"primary",
                            "action_button"=>"testing29chars...............",
                            "buttons"=>
                             [{"content_type"=>"button",
                               "content"=>
                                {"title"=>"Listen to good music",
                                 "accepts"=>["music", "listen", "Listen to good music", "Listen to good music"],
                                 "payload"=>"Listen to good music"}},
                              {"content_type"=>"button",
                               "content"=>
                                {"payload"=>"Manage my Dropbox account",
                                 "title"=>"Manage my Dropbox account",
                                 "accepts"=>["dropbox", "Manage my Dropbox account", "Manage my Dropbox account"]}},
                              {"content"=>{"title"=>"Tell me a joke", "accepts"=>["Tell me a joke", "Tell me a joke"], "payload"=>"Tell me a joke"},
                               "content_type"=>"button"},
                              {"content"=>{"payload"=>"123 Tell me a joke", "title"=>"123 Tell me a joke", "accepts"=>["123 Tell me a joke", "123 Tell me a joke"]},
                               "content_type"=>"button"}],
                            "title"=>"What would you like to do today?"}}
                      },
                      inbox: whatsapp_channel.inbox
          )

          stub_request(:post, 'https://graph.facebook.com/v13.0/123456789/messages')
            .with(
              body: {"messaging_product":"whatsapp","to":"+123456789","interactive":{"type":"list","body":{"text":"test"},"action":{"button":"testing29chars......","sections":[{"title":"Options","rows":[{"id":"Listen to good music","title":"Listen to good music"},{"id":"Manage my Dropbox account","title":"Manage my Dropbox accoun"},{"id":"Tell me a joke","title":"Tell me a joke"},{"id":"123 Tell me a joke","title":"123 Tell me a joke"}]}]}},"type":"interactive"}.to_json
            )
            .to_return(status: 200, body: whatsapp_response.to_json, headers: response_headers)
          expect(service.send_message('+123456789', message)).to eq 'message_id'
        end

        it 'calls message endpoints for interactive list buttons messages with header' do
          stub_request(:get, /oauth\/access_token/).
          to_return(status: 200, body: {"access_token": "1234", expires_in: Time.current.to_i }.to_json, headers: response_headers)
 
          stub_request(:get, /debug_token/).
          to_return(status: 200, body: {'data': {'expires_at': (Time.current + 10.days).to_i}}.to_json, headers: response_headers)

          message = create(
            :message, message_type: :outgoing, content: 'test', content_type: 'input_select',
                      content_attributes: {
                        'items' => [{ 'title' => 'test', 'value' => 'test' }, { 'title' => 'test 2', 'value' => 'test 2' }, { 'title' => 'test 3', 'value' => 'test 3'}, { 'title' => 'test 4', 'value' => 'test 4' } ],
                        'message_payload' => {"content_type"=>"question",
                          "content"=>
                           {"style"=>"primary",
                            "header"=>"testing29chars...............",
                            "buttons"=>
                             [{"content_type"=>"button",
                               "content"=>
                                {"title"=>"Listen to good music",
                                 "accepts"=>["music", "listen", "Listen to good music", "Listen to good music"],
                                 "payload"=>"Listen to good music"}},
                              {"content_type"=>"button",
                               "content"=>
                                {"payload"=>"Manage my Dropbox account",
                                 "title"=>"Manage my Dropbox account",
                                 "accepts"=>["dropbox", "Manage my Dropbox account", "Manage my Dropbox account"]}},
                              {"content"=>{"title"=>"Tell me a joke", "accepts"=>["Tell me a joke", "Tell me a joke"], "payload"=>"Tell me a joke"},
                               "content_type"=>"button"},
                              {"content"=>{"payload"=>"123 Tell me a joke", "title"=>"123 Tell me a joke", "accepts"=>["123 Tell me a joke", "123 Tell me a joke"]},
                               "content_type"=>"button"}],
                            "title"=>"What would you like to do today?"}}
                      },
                      inbox: whatsapp_channel.inbox
          )

          stub_request(:post, 'https://graph.facebook.com/v13.0/123456789/messages')
            .with(
              body: {"messaging_product":"whatsapp","to":"+123456789","interactive":{"type":"list","body":{"text":"test"},"action":{"button":"Select","sections":[{"title":"Options","rows":[{"id":"Listen to good music","title":"Listen to good music"},{"id":"Manage my Dropbox account","title":"Manage my Dropbox accoun"},{"id":"Tell me a joke","title":"Tell me a joke"},{"id":"123 Tell me a joke","title":"123 Tell me a joke"}]}]},"header":{"type":"text","text":"testing29chars..............."}},"type":"interactive"}.to_json
            )
            .to_return(status: 200, body: whatsapp_response.to_json, headers: response_headers)
          expect(service.send_message('+123456789', message)).to eq 'message_id'
        end

        it 'calls message endpoints for interactive list buttons messages with footer' do
          stub_request(:get, /oauth\/access_token/).
          to_return(status: 200, body: {"access_token": "1234", expires_in: Time.current.to_i }.to_json, headers: response_headers)
 
          stub_request(:get, /debug_token/).
          to_return(status: 200, body: {'data': {'expires_at': (Time.current + 10.days).to_i}}.to_json, headers: response_headers)

          message = create(
            :message, message_type: :outgoing, content: 'test', content_type: 'input_select',
                      content_attributes: {
                        'items' => [{ 'title' => 'test', 'value' => 'test' }, { 'title' => 'test 2', 'value' => 'test 2' }, { 'title' => 'test 3', 'value' => 'test 3'}, { 'title' => 'test 4', 'value' => 'test 4' } ],
                        'message_payload' => {"content_type"=>"question",
                          "content"=>
                           {"style"=>"primary",
                            "footer"=>"testing29chars...............",
                            "buttons"=>
                             [{"content_type"=>"button",
                               "content"=>
                                {"title"=>"Listen to good music",
                                 "accepts"=>["music", "listen", "Listen to good music", "Listen to good music"],
                                 "payload"=>"Listen to good music"}},
                              {"content_type"=>"button",
                               "content"=>
                                {"payload"=>"Manage my Dropbox account",
                                 "title"=>"Manage my Dropbox account",
                                 "accepts"=>["dropbox", "Manage my Dropbox account", "Manage my Dropbox account"]}},
                              {"content"=>{"title"=>"Tell me a joke", "accepts"=>["Tell me a joke", "Tell me a joke"], "payload"=>"Tell me a joke"},
                               "content_type"=>"button"},
                              {"content"=>{"payload"=>"123 Tell me a joke", "title"=>"123 Tell me a joke", "accepts"=>["123 Tell me a joke", "123 Tell me a joke"]},
                               "content_type"=>"button"}],
                            "title"=>"What would you like to do today?"}}
                      },
                      inbox: whatsapp_channel.inbox
          )

          stub_request(:post, 'https://graph.facebook.com/v13.0/123456789/messages')
            .with(
              body: {"messaging_product":"whatsapp","to":"+123456789","interactive":{"type":"list","body":{"text":"test"},"action":{"button":"Select","sections":[{"title":"Options","rows":[{"id":"Listen to good music","title":"Listen to good music"},{"id":"Manage my Dropbox account","title":"Manage my Dropbox accoun"},{"id":"Tell me a joke","title":"Tell me a joke"},{"id":"123 Tell me a joke","title":"123 Tell me a joke"}]}]},"footer":{"text":"testing29chars..............."}},"type":"interactive"}.to_json
            )
            .to_return(status: 200, body: whatsapp_response.to_json, headers: response_headers)
          expect(service.send_message('+123456789', message)).to eq 'message_id'
        end

        it 'calls message endpoints for interactive list buttons messages with description' do
          stub_request(:get, /oauth\/access_token/).
          to_return(status: 200, body: {"access_token": "1234", expires_in: Time.current.to_i }.to_json, headers: response_headers)
 
          stub_request(:get, /debug_token/).
          to_return(status: 200, body: {'data': {'expires_at': (Time.current + 10.days).to_i}}.to_json, headers: response_headers)
 
          message = create(
            :message, message_type: :outgoing, content: 'test', content_type: 'input_select',
                      content_attributes: {
                        'items' => [{ 'title' => 'test', 'value' => 'test' }, { 'title' => 'test 2', 'value' => 'test 2' }, { 'title' => 'test 3', 'value' => 'test 3'}, { 'title' => 'test 4', 'value' => 'test 4' } ],
                        'message_payload' => {"content_type"=>"question",
                          "content"=>
                           {"style"=>"primary",
                            "buttons"=>
                             [{"content_type"=>"button",
                               "content"=>
                                {"title"=>"Listen to good music",
                                 "description"=>"Description 1",
                                 "accepts"=>["music", "listen", "Listen to good music", "Listen to good music"],
                                 "payload"=>"Listen to good music"}},
                              {"content_type"=>"button",
                               "content"=>
                                {"payload"=>"Manage my Dropbox account",
                                 "title"=>"Manage my Dropbox account",
                                 "accepts"=>["dropbox", "Manage my Dropbox account", "Manage my Dropbox account"]}},
                              {"content"=>{"title"=>"Tell me a joke", "accepts"=>["Tell me a joke", "Tell me a joke"], "payload"=>"Tell me a joke"},
                               "content_type"=>"button"},
                              {"content"=>{"payload"=>"123 Tell me a joke", "title"=>"123 Tell me a joke", "accepts"=>["123 Tell me a joke", "123 Tell me a joke"]},
                               "content_type"=>"button"}],
                            "title"=>"What would you like to do today?"}}
                      },
                      inbox: whatsapp_channel.inbox
          )

          stub_request(:post, 'https://graph.facebook.com/v13.0/123456789/messages')
            .with(
              body: {"messaging_product":"whatsapp","to":"+123456789","interactive":{"type":"list","body":{"text":"test"},"action":{"button":"Select","sections":[{"title":"Options","rows":[{"id":"Listen to good music","title":"Listen to good music","description":"Description 1"},{"id":"Manage my Dropbox account","title":"Manage my Dropbox accoun"},{"id":"Tell me a joke","title":"Tell me a joke"},{"id":"123 Tell me a joke","title":"123 Tell me a joke"}]}]}},"type":"interactive"}.to_json
            )
            .to_return(status: 200, body: whatsapp_response.to_json, headers: response_headers)
          expect(service.send_message('+123456789', message)).to eq 'message_id'
        end

        it 'calls message endpoints for interactive list buttons messages with one button has a section and others without' do
          stub_request(:get, /oauth\/access_token/).
          to_return(status: 200, body: {"access_token": "1234", expires_in: Time.current.to_i }.to_json, headers: response_headers)
 
          stub_request(:get, /debug_token/).
          to_return(status: 200, body: {'data': {'expires_at': (Time.current + 10.days).to_i}}.to_json, headers: response_headers)

          message = create(
            :message, message_type: :outgoing, content: 'test', content_type: 'input_select',
                      content_attributes: {
                        'items' => [{ 'title' => 'test', 'value' => 'test' }, { 'title' => 'test 2', 'value' => 'test 2' }, { 'title' => 'test 3', 'value' => 'test 3'}, { 'title' => 'test 4', 'value' => 'test 4' } ],
                        'message_payload' => {"content_type"=>"question",
                          "content"=>
                           {"style"=>"primary",
                            "buttons"=>
                             [{"content_type"=>"button",
                               "content"=>
                                {"title"=>"Listen to good music",
                                 "accepts"=>["music", "listen", "Listen to good music", "Listen to good music"],
                                 "section_title"=>"Section 1",
                                 "payload"=>"Listen to good music"}},
                              {"content_type"=>"button",
                               "content"=>
                                {"payload"=>"Manage my Dropbox account",
                                 "title"=>"Manage my Dropbox account",
                                 "accepts"=>["dropbox", "Manage my Dropbox account", "Manage my Dropbox account"]}},
                              {"content"=>{"title"=>"Tell me a joke", "accepts"=>["Tell me a joke", "Tell me a joke"], "payload"=>"Tell me a joke"},
                               "content_type"=>"button"},
                              {"content"=>{"payload"=>"123 Tell me a joke", "title"=>"123 Tell me a joke", "accepts"=>["123 Tell me a joke", "123 Tell me a joke"]},
                               "content_type"=>"button"}],
                            "title"=>"What would you like to do today?"}}
                      },
                      inbox: whatsapp_channel.inbox
          )

          stub_request(:post, 'https://graph.facebook.com/v13.0/123456789/messages')
            .with(
              body: {"messaging_product":"whatsapp","to":"+123456789","interactive":{"type":"list","body":{"text":"test"},"action":{"button":"Select","sections":[{"title":"Section 1","rows":[{"id":"Listen to good music","title":"Listen to good music"}]},{"title":"Options","rows":[{"id":"Manage my Dropbox account","title":"Manage my Dropbox accoun"},{"id":"Tell me a joke","title":"Tell me a joke"},{"id":"123 Tell me a joke","title":"123 Tell me a joke"}]}]}},"type":"interactive"}.to_json
            )
            .to_return(status: 200, body: whatsapp_response.to_json, headers: response_headers)
          expect(service.send_message('+123456789', message)).to eq 'message_id'
        end

        it 'calls message endpoints for interactive list buttons messages with one section' do
          stub_request(:get, /oauth\/access_token/).
          to_return(status: 200, body: {"access_token": "1234", expires_in: Time.current.to_i }.to_json, headers: response_headers)
 
          stub_request(:get, /debug_token/).
          to_return(status: 200, body: {'data': {'expires_at': (Time.current + 10.days).to_i}}.to_json, headers: response_headers)

          message = create(
            :message, message_type: :outgoing, content: 'test', content_type: 'input_select',
                      content_attributes: {
                        'items' => [{ 'title' => 'test', 'value' => 'test' }, { 'title' => 'test 2', 'value' => 'test 2' }, { 'title' => 'test 3', 'value' => 'test 3'}, { 'title' => 'test 4', 'value' => 'test 4' } ],
                        'message_payload' => {"content_type"=>"question",
                          "content"=>
                           {"style"=>"primary",
                            "buttons"=>
                             [{"content_type"=>"button",
                               "content"=>
                                {"title"=>"Listen to good music",
                                 "accepts"=>["music", "listen", "Listen to good music", "Listen to good music"],
                                 "section_title"=>"Section 1",
                                 "payload"=>"Listen to good music"}},
                              {"content_type"=>"button",
                               "content"=>
                                {"payload"=>"Manage my Dropbox account",
                                 "title"=>"Manage my Dropbox account",
                                 "section_title"=>"Section 1",
                                 "accepts"=>["dropbox", "Manage my Dropbox account", "Manage my Dropbox account"]}},
                              {"content"=>{"title"=>"Tell me a joke", "section_title"=>"Section 1", "accepts"=>["Tell me a joke", "Tell me a joke"], "payload"=>"Tell me a joke"},
                               "content_type"=>"button"},
                              {"content"=>{"payload"=>"123 Tell me a joke", "section_title"=>"Section 1", "title"=>"123 Tell me a joke", "accepts"=>["123 Tell me a joke", "123 Tell me a joke"]},
                               "content_type"=>"button"}],
                            "title"=>"What would you like to do today?"}}
                      },
                      inbox: whatsapp_channel.inbox
          )

          stub_request(:post, 'https://graph.facebook.com/v13.0/123456789/messages')
            .with(
              body: {"messaging_product":"whatsapp","to":"+123456789","interactive":{"type":"list","body":{"text":"test"},"action":{"button":"Select","sections":[{"title":"Section 1","rows":[{"id":"Listen to good music","title":"Listen to good music"},{"id":"Manage my Dropbox account","title":"Manage my Dropbox accoun"},{"id":"Tell me a joke","title":"Tell me a joke"},{"id":"123 Tell me a joke","title":"123 Tell me a joke"}]}]}},"type":"interactive"}.to_json
            )
            .to_return(status: 200, body: whatsapp_response.to_json, headers: response_headers)
          expect(service.send_message('+123456789', message)).to eq 'message_id'
        end

        it 'calls message endpoints for interactive list buttons messages with two sections' do
          stub_request(:get, /oauth\/access_token/).
          to_return(status: 200, body: {"access_token": "1234", expires_in: Time.current.to_i }.to_json, headers: response_headers)
 
          stub_request(:get, /debug_token/).
          to_return(status: 200, body: {'data': {'expires_at': (Time.current + 10.days).to_i}}.to_json, headers: response_headers)

          message = create(
            :message, message_type: :outgoing, content: 'test', content_type: 'input_select',
                      content_attributes: {
                        'items' => [{ 'title' => 'test', 'value' => 'test' }, { 'title' => 'test 2', 'value' => 'test 2' }, { 'title' => 'test 3', 'value' => 'test 3'}, { 'title' => 'test 4', 'value' => 'test 4' } ],
                        'message_payload' => {"content_type"=>"question",
                          "content"=>
                           {"style"=>"primary",
                            "buttons"=>
                             [{"content_type"=>"button",
                               "content"=>
                                {"title"=>"Listen to good music",
                                 "accepts"=>["music", "listen", "Listen to good music", "Listen to good music"],
                                 "section_title"=>"Section 1",
                                 "payload"=>"Listen to good music"}},
                              {"content_type"=>"button",
                               "content"=>
                                {"payload"=>"Manage my Dropbox account",
                                 "title"=>"Manage my Dropbox account",
                                 "section_title"=>"Section 1",
                                 "accepts"=>["dropbox", "Manage my Dropbox account", "Manage my Dropbox account"]}},
                              {"content"=>{"title"=>"Tell me a joke", "section_title"=>"Section 2", "accepts"=>["Tell me a joke", "Tell me a joke"], "payload"=>"Tell me a joke"},
                               "content_type"=>"button"},
                              {"content"=>{"payload"=>"123 Tell me a joke", "section_title"=>"Section 1", "title"=>"123 Tell me a joke", "accepts"=>["123 Tell me a joke", "123 Tell me a joke"]},
                               "content_type"=>"button"}],
                            "title"=>"What would you like to do today?"}}
                      },
                      inbox: whatsapp_channel.inbox
          )

          stub_request(:post, 'https://graph.facebook.com/v13.0/123456789/messages')
            .with(
              body: {"messaging_product":"whatsapp","to":"+123456789","interactive":{"type":"list","body":{"text":"test"},"action":{"button":"Select","sections":[{"title":"Section 1","rows":[{"id":"Listen to good music","title":"Listen to good music"},{"id":"Manage my Dropbox account","title":"Manage my Dropbox accoun"},{"id":"123 Tell me a joke","title":"123 Tell me a joke"}]},{"title":"Section 2","rows":[{"id":"Tell me a joke","title":"Tell me a joke"}]}]}},"type":"interactive"}.to_json
            )
            .to_return(status: 200, body: whatsapp_response.to_json, headers: response_headers)
          expect(service.send_message('+123456789', message)).to eq 'message_id'
        end
      end
    end
  end
end
