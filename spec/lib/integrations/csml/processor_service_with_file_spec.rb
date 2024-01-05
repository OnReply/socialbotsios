require 'rails_helper'

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
      context 'creates a file message' do
        it 'should image file' do
          stub_request(:get, /jpg/).to_return(status: 200,
            body: '',
            headers: {'Content-Type': 'image/jpeg'})
          csml_response = ActiveSupport::HashWithIndifferentAccess.new(
            messages: [{
              payload: {
                content_type: 'file',
                content: { url: 'https://i.ibb.co/5RXy9fG/My-project-1.jpg' }
              }
            }]
          )
          allow(csml_client).to receive(:run).and_return(csml_response)
          processor.perform
          expect(conversation.messages.last.content).to eql('')
          expect(conversation.messages.last.attachments.first.file_type).to eql('image')
        end

        it 'should video file' do
          stub_request(:get, /mp4/).to_return(status: 200,
            body: '',
            headers: {'Content-Type': 'video/mp4'})
          csml_response = ActiveSupport::HashWithIndifferentAccess.new(
            messages: [{
              payload: {
                content_type: 'file',
                content: { url: 'https://media.giphy.com/media/3oKIPsx2VAYAgEHC12/giphy.mp4' }
              }
            }]
          )
          allow(csml_client).to receive(:run).and_return(csml_response)
          processor.perform
          expect(conversation.messages.last.content).to eql('')
          expect(conversation.messages.last.attachments.first.file_type).to eql('video')
        end

        it 'should document file' do
          stub_request(:get, /pdf/).to_return(status: 200,
            body: '',
            headers: {'Content-Type': 'application/pdf'})
          csml_response = ActiveSupport::HashWithIndifferentAccess.new(
            messages: [{
              payload: {
                content_type: 'file',
                content: { url: 'https://nyphil.org/~/media/pdfs/program-notes/1819/Brahms-Symphony-No-4.pdf' }
              }
            }]
          )
          allow(csml_client).to receive(:run).and_return(csml_response)
          processor.perform
          expect(conversation.messages.last.content).to eql('')
          expect(conversation.messages.last.attachments.first.file_type).to eql('file')
        end

        it 'should audio file' do
          stub_request(:get, /mp3/).to_return(status: 200,
            body: '',
            headers: {'Content-Type': 'audio/mpeg'})
          csml_response = ActiveSupport::HashWithIndifferentAccess.new(
            messages: [{
              payload: {
                content_type: 'file',
                content: { url: 'https://file-examples.com/storage/fee3d1095964bab199aee29/2017/11/file_example_MP3_700KB.mp3' }
              }
            }]
          )
          allow(csml_client).to receive(:run).and_return(csml_response)
          processor.perform
          expect(conversation.messages.last.content).to eql('')
          expect(conversation.messages.last.attachments.first.file_type).to eql('audio')
        end
      end
    end
  end
end
