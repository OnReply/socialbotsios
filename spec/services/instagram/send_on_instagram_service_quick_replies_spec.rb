require 'rails_helper'

describe Instagram::SendOnInstagramService do
  subject(:send_reply_service) { described_class.new(message: message) }

  before do
    create(:message, message_type: :incoming, inbox: instagram_inbox, account: account, conversation: conversation)
  end

  let!(:account) { create(:account) }
  let!(:instagram_channel) { create(:channel_instagram_fb_page, account: account, instagram_id: 'chatwoot-app-user-id-1') }
  let!(:instagram_inbox) { create(:inbox, channel: instagram_channel, account: account, greeting_enabled: false) }
  let!(:contact) { create(:contact, account: account) }
  let(:contact_inbox) { create(:contact_inbox, contact: contact, inbox: instagram_inbox) }
  let(:conversation) { create(:conversation, contact: contact, inbox: instagram_inbox, contact_inbox: contact_inbox) }
  let(:response) { double }

  describe '#perform' do
    context 'with reply' do
      before do
        allow(Facebook::Messenger::Configuration::AppSecretProofCalculator).to receive(:call).and_return('app_secret_key', 'access_token')
      end

      context 'without message_tag HUMAN_AGENT' do
        before do
          InstallationConfig.where(name: 'ENABLE_MESSENGER_CHANNEL_HUMAN_AGENT').first_or_create(value: false)
        end

        it 'if message with buttons is sent from chatwoot and is outgoing' do
          message = create(:message, message_type: 'outgoing', inbox: instagram_inbox, account: account, conversation: conversation,
                                     content_type: 'input_select',
                                     content_attributes: { 'items' => [{ 'title' => 'test-title', 'value' => 'test-value' }] })

          stub_request(:post, %r{me/messages})
            .to_return(status: 200, body: '{"message_id": "anyrandommessageid1234567890"}', headers: { 'Content-Type' => 'application/json' })

          response = ::Instagram::SendOnInstagramService.new(message: message).perform

          expect(response.parsed_response).to eq({ 'message_id' => 'anyrandommessageid1234567890' })
          expect(WebMock).to have_requested(:post, %r{me/messages})
            .with(body: hash_including(message: { :text => 'Incoming Message',
                                                  :quick_replies => [{ :content_type => 'text', :title => 'test-title',
                                                                       :payload => 'test-value' }] }))
        end
      end
    end
  end
end
