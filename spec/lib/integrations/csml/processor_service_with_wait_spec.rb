require 'rails_helper'
include ActiveJob::TestHelper

describe Integrations::Csml::ProcessorService do
  let(:account) { create(:account) }
  let(:inbox) { create(:inbox, account: account) }
  let(:agent_bot) { create(:agent_bot, :skip_validate, bot_type: 'csml', account: account) }
  let(:agent_bot_inbox) { create(:agent_bot_inbox, agent_bot: agent_bot, inbox: inbox, account: account) }
  let(:conversation) { create(:conversation, account: account, status: :pending) }
  let(:message) { create(:message, account: account, conversation: conversation) }
  let(:event_name) { 'message.created' }
  let(:event_data) { { message: message } }

  describe '#perform' do
    let(:csml_client) { double }
    let(:processor) { described_class.new(event_name: event_name, agent_bot: agent_bot, event_data: event_data) }

    before do
      allow(CsmlEngine).to receive(:new).and_return(csml_client)
    end

    context 'when a new message is returned from CSML' do
      it 'creates a text message' do
        with_modified_env FEATURE_IMPROVES_CSML: 'true' do
          csml_response = ActiveSupport::HashWithIndifferentAccess.new(
            messages: [
              { payload: { content_type: 'text', content: { text: 'hello payload' } } },
              { 'payload' => { 'content_type' => 'text', 'content' => { 'text' => 'Wait 5 seconds' } }, 'interaction_order' => 0,
                'conversation_id' => 'dc002a4b-dc78-44e9-9e1b-728527123bd8', 'direction' => 'SEND' },
              { 'payload' => { 'content_type' => 'wait', 'content' => { 'duration' => 5000 } }, 'interaction_order' => 0,
                'conversation_id' => 'dc002a4b-dc78-44e9-9e1b-728527123bd8', 'direction' => 'SEND' },
              { 'payload' => { 'content_type' => 'text', 'content' => { 'text' => 'Wait 10 seconds' } }, 'interaction_order' => 0,
                'conversation_id' => 'dc002a4b-dc78-44e9-9e1b-728527123bd8', 'direction' => 'SEND' },
              { 'payload' => { 'content_type' => 'wait', 'content' => { 'duration' => 10_000 } }, 'interaction_order' => 0,
                'conversation_id' => 'dc002a4b-dc78-44e9-9e1b-728527123bd8', 'direction' => 'SEND' },
              { 'payload' => { 'content_type' => 'text', 'content' => { 'text' => 'Enjoy ❤' } }, 'interaction_order' => 0,
                'conversation_id' => 'dc002a4b-dc78-44e9-9e1b-728527123bd8', 'direction' => 'SEND' }
            ]
          )
          allow(csml_client).to receive(:run).and_return(csml_response)

          clear_enqueued_jobs
          processor.perform
          perform_enqueued_jobs
          expect(conversation.messages.last.content).to eql('Enjoy ❤')
        end
      end
    end
  end
end
