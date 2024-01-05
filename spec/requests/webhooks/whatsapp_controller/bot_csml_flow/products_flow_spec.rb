require 'rails_helper'
require 'sidekiq/testing'

RSpec.describe 'Webhooks::WhatsappController', type: :request do
  include ActiveJob::TestHelper
  before do
    response_headers = { 'Content-Type' => 'application/json' }

    stub_request(:get, /access_token/).
    to_return(status: 200, body: {'data': {'expires_at': (Time.current + 10.days).to_i}}.to_json, headers: response_headers)
    stub_request(:get, /subscribed_apps/).
    to_return(status: 200, body: {"data": [{"whatsapp_business_api_data": {"link": "https://www.facebook.com/games/?app_id=742189254309938","name": "Baggio - 41998154704","id": "742189254309938"}}]}.to_json, headers: response_headers)
    stub_request(:post, "https://webhooks.socialbot.dev/webhook/new-inbox-added").
    to_return(status: 200, body: "{}", headers: {})

    stub_request(:post, /validate/).
    to_return(status: 200, body: '{"valid": true}', headers:  { 'Content-Type' => 'application/json' })

    stub_request(:post, /run/).
    to_return(status: 200, body: {"messages"=>[{"payload"=>{"content_type"=>"text", "content"=>{"text"=>"2 Hello stranger! 👋"}}, "interaction_order"=>0, "conversation_id"=>"649a42f1e34ed4254e26250c", "direction"=>"SEND"}, {"payload"=>{"content_type"=>"Component.whatsappproducts", "content"=>{"products"=>[{"skus"=>["5r4tap9sy6", "rao5dr72th", "8ghbwwal2r"], "section_title"=>"section title"}], "catalog_id"=>"1183719818989019", "header"=>"testing2", "content"=>"testing body"}}, "interaction_order"=>0, "conversation_id"=>"649a42f1e34ed4254e26250c", "direction"=>"SEND"}], "conversation_end"=>false, "request_id"=>"8ffdee12-a373-4a32-8e9d-9900a885811d", "received_at"=>"2023-06-27T02:01:22.003Z", "client"=>{"bot_id"=>"chatwoot-bot-2", "user_id"=>"554196910256", "channel_id"=>"chatwoot-bot-inbox-2"}}.to_json, headers:  { 'Content-Type' => 'application/json' })

    stub_request(:post, /messages/)
    .to_return(status: 200, body: whatsapp_response.to_json, headers: response_headers)

    create(:installation_config, name: 'CSML_BOT_HOST', value: 'https://social-bot-csml-server-staging.herokuapp.com')
    create(:installation_config, name: 'CSML_BOT_API_KEY', value: '123564651')
  
    whatsapp_channel.provider_config['phone_number_id'] = '110305898707701'
    whatsapp_channel.provider_config['business_account_id'] = '119008101162708'
    whatsapp_channel.provider_config['webhook_verify_token'] = '01d18edc1d0394733db0b89d47cb4460'
    whatsapp_channel.save
  end


  subject(:service) { described_class.new(whatsapp_channel: whatsapp_channel) }

  describe 'POST /webhooks/whatsapp' do
    let(:account) { create(:account) }
    let(:whatsapp_channel) { create(:channel_whatsapp, phone_number: '+554198154704', provider: 'whatsapp_cloud', validate_provider_config: false, sync_templates: false, provider_config: {phone_number_id: '110305898707701', business_account_id: '119008101162708', webhook_verify_token: '01d18edc1d0394733db0b89d47cb4460'}, account: account ) }

    let!(:agent_bot) { create(:agent_bot, outgoing_url: nil, bot_type: 'csml', account: account, bot_config: {csml_content: "start:\n  say \"2 Hello stranger! 👋\"\n  say Component.WhatsappProducts(content=\"testing body\", header=\"testing2\", catalog_id=\"1183719818989019\", products=[{\"section_title\": \"section title\", \"skus\": [\"5r4tap9sy6\", \"rao5dr72th\", \"8ghbwwal2r\"]}])\n  hold\n  say \"2 Enjoy ❤\"\n  goto end"}  ) }
    let!(:agent_bot_inbox) { create(:agent_bot_inbox, inbox: whatsapp_channel.inbox, agent_bot: agent_bot, account:account )}

    let(:whatsapp_response) { { messages: [{ id: 'message_id' }] } }
    let(:request_receive_params) {
      {"object"=>"whatsapp_business_account", "entry"=>[{"id"=>"119008101162708", "changes"=>[{"value"=>{"messaging_product"=>"whatsapp", "metadata"=>{"display_phone_number"=>"554198154704", "phone_number_id"=>"110305898707701"}, "contacts"=>[{"profile"=>{"name"=>"Douglas Lara"}, "wa_id"=>"554196910256"}], "messages"=>[{"from"=>"554196910256", "id"=>"wamid.HBgMNTU0MTk2OTEwMjU2FQIAEhgWM0VCMDY1NDk1NTFCNENDNDY3REU2NgA=", "timestamp"=>"1687778555", "text"=>{"body"=>"Hi Testing..."}, "type"=>"text"}]}, "field"=>"messages"}]}], "phone_number"=>"+554198154704", "whatsapp"=>{"object"=>"whatsapp_business_account", "entry"=>[{"id"=>"119008101162708", "changes"=>[{"value"=>{"messaging_product"=>"whatsapp", "metadata"=>{"display_phone_number"=>"554198154704", "phone_number_id"=>"110305898707701"}, "contacts"=>[{"profile"=>{"name"=>"Douglas Lara"}, "wa_id"=>"554196910256"}], "messages"=>[{"from"=>"554196910256", "id"=>"wamid.HBgMNTU0MTk2OTEwMjU2FQIAEhgWM0VCMDY1NDk1NTFCNENDNDY3REU2NgA=", "timestamp"=>"1687778555", "text"=>{"body"=>"Hi Testing..."}, "type"=>"text"}]}, "field"=>"messages"}]}]}}
    }


    it 'should send products' do
      perform_enqueued_jobs do
        post '/webhooks/whatsapp/+554198154704', params: request_receive_params
      end

      expect(response).to have_http_status(:success)
      expect(Message.last.content_type).to eq('integrations')
    end

    it 'should send products with wait feature' do        
      with_modified_env FEATURE_IMPROVES_CSML: 'true' do
        perform_enqueued_jobs do
          post '/webhooks/whatsapp/+554198154704', params: request_receive_params
        end

        expect(response).to have_http_status(:success)
        expect(Message.last.content_type).to eq('integrations')
      end
    end


    it 'should error without catalog_id' do
      stub_request(:post, /run/).
      to_return(status: 200, body: {"messages"=>[{"payload"=>{"content_type"=>"text", "content"=>{"text"=>"2 Hello stranger! 👋"}}, "interaction_order"=>0, "conversation_id"=>"649a42f1e34ed4254e26250c", "direction"=>"SEND"}, {"payload"=>{"content_type"=>"error", "content"=>{"error"=>"catalog_id is a required parameter at line 3, column 17 at flow [chatwoot_bot_flow]"}}, "interaction_order"=>0, "conversation_id"=>"649a42f1e34ed4254e26250c", "direction"=>"SEND"}], "conversation_end"=>true, "request_id"=>"4ed74c96-0379-4523-8381-21555dc377a3", "received_at"=>"2023-06-27T02:58:01.121Z", "client"=>{"bot_id"=>"chatwoot-bot-2", "user_id"=>"554196910256", "channel_id"=>"chatwoot-bot-inbox-2"}}.to_json, headers:  { 'Content-Type' => 'application/json' })

      perform_enqueued_jobs do
        post '/webhooks/whatsapp/+554198154704', params: request_receive_params
      end

      expect(response).to have_http_status(:success)
      expect(Message.last.content_type).to eq('text')
    end

    context 'should receive whatsapp products message statuss' do
      let(:request_receive_params) {
        {"object"=>"whatsapp_business_account", "entry"=>[{"id"=>"119008101162708", "changes"=>[{"value"=>{"messaging_product"=>"whatsapp", "metadata"=>{"display_phone_number"=>"554198154704", "phone_number_id"=>"110305898707701"}, "contacts"=>[{"profile"=>{"name"=>"Douglas Lara"}, "wa_id"=>"554196910256"}], "messages"=>[{"from"=>"554196910256", "id"=>"wamid.HBgMNTU0MTk2OTEwMjU2FQIAEhgUM0E2MkU1QTA0MjA0MDZFQTc5OEYA", "timestamp"=>"1688122724", "type"=>"order", "order"=>{"catalog_id"=>"1183719818989019", "product_items"=>[{"product_retailer_id"=>"5r4tap9sy6", "quantity"=>2, "item_price"=>5, "currency"=>"USD"}]}}]}, "field"=>"messages"}]}], "phone_number"=>"+554198154704", "whatsapp"=>{"object"=>"whatsapp_business_account", "entry"=>[{"id"=>"119008101162708", "changes"=>[{"value"=>{"messaging_product"=>"whatsapp", "metadata"=>{"display_phone_number"=>"554198154704", "phone_number_id"=>"110305898707701"}, "contacts"=>[{"profile"=>{"name"=>"Douglas Lara"}, "wa_id"=>"554196910256"}], "messages"=>[{"from"=>"554196910256", "id"=>"wamid.HBgMNTU0MTk2OTEwMjU2FQIAEhgUM0E2MkU1QTA0MjA0MDZFQTc5OEYA", "timestamp"=>"1688122724", "type"=>"order", "order"=>{"catalog_id"=>"1183719818989019", "product_items"=>[{"product_retailer_id"=>"5r4tap9sy6", "quantity"=>2, "item_price"=>5, "currency"=>"USD"}]}}]}, "field"=>"messages"}]}]}}
      }

      it do
        with_modified_env WHATSAPP_ORDERS_WEBHOOK: 'https://webhooks.socialbot.dev/webhook/new-whatsapp-order-staging' do

          perform_enqueued_jobs do
            post '/webhooks/whatsapp/+554198154704', params: request_receive_params
            assert_performed_jobs 1, only: WebhookJob
          end
          expect(Message.last.content_type).to eq('integrations')  
        end
      end
    end
  end
end

