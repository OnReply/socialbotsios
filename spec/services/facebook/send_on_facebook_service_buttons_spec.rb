require 'rails_helper'

describe Facebook::SendOnFacebookService do
  subject(:send_reply_service) { described_class.new(message: message) }

  before do
    allow(Facebook::Messenger::Subscriptions).to receive(:subscribe).and_return(true)
    allow(bot).to receive(:deliver).and_return({ recipient_id: '1008372609250235', message_id: 'mid.1456970487936:c34767dfe57ee6e339' }.to_json)
    create(:message, message_type: :incoming, inbox: facebook_inbox, account: account, conversation: conversation)
  end

  let!(:account) { create(:account) }
  let(:bot) { class_double(Facebook::Messenger::Bot).as_stubbed_const }
  let!(:facebook_channel) { create(:channel_facebook_page, account: account) }
  let!(:facebook_inbox) { create(:inbox, channel: facebook_channel, account: account) }
  let!(:contact) { create(:contact, account: account) }
  let(:contact_inbox) { create(:contact_inbox, contact: contact, inbox: facebook_inbox) }
  let(:conversation) { create(:conversation, contact: contact, inbox: facebook_inbox, contact_inbox: contact_inbox) }

  describe '#perform' do
    context 'with buttons' do
      it 'if message is sent from chatwoot and is outgoing' do
        message = create(
          :message,
          content_type: 'input_select',
          content_attributes: { 'items' => [{ 'title' => 'test-title', 'value' => 'test-value' }] },
          message_type: 'outgoing',
          inbox: facebook_inbox,
          account: account,
          conversation: conversation
        )

        ::Facebook::SendOnFacebookService.new(message: message).perform
        expect(bot).to have_received(:deliver)
      end
    end
  end
end
