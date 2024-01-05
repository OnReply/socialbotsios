require 'rails_helper'

RSpec.describe Channel::Telegram do
  let(:telegram_channel) { create(:channel_telegram) }

  context 'when a valid message and empty attachments' do
    it 'send message with reply_markup and image' do
      message = create(
        :message, message_type: :outgoing, content: 'test', content_type: 'input_select',
                  content_attributes: {
                    'items' => [{ 'title' => 'test', 'value' => 'test' }],
                    :message_payload => { 'content_type' => 'question',
                                          'content' =>
                        { 'image' => 'https://media4.giphy.com/media/dzaUX7CAG0Ihi/giphy.gif',
                          'buttons' =>
                          [
                            { 'content_type' => 'button',
                              'content' => { 'title' => 'test', 'accepts' => ['teste'] } }
                          ],
                          'title' => 'What would you like to do today?' } }
                  },
                  conversation: create(:conversation, inbox: telegram_channel.inbox, additional_attributes: { 'chat_id' => '123' })
      )

      stub_request(:post, "https://api.telegram.org/bot#{telegram_channel.bot_token}/sendPhoto")
        .with(
          body: 'chat_id=123&caption=test&photo=https%3A%2F%2Fmedia4.giphy.com%2Fmedia%2FdzaUX7CAG0Ihi%2Fgiphy.gif&reply_markup=%7B%22one_time_keyboard%22%3Atrue%2C%22inline_keyboard%22%3A%5B%5B%7B%22text%22%3A%22test%22%2C%22callback_data%22%3A%22test%22%7D%5D%5D%7D'
        )
        .to_return(
          status: 200,
          body: { result: { message_id: 'telegram_123' } }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )

      expect(telegram_channel.send_message_on_telegram(message)).to eq('telegram_123')
    end

    it 'send message with reply_markup and video' do
      message = create(
        :message, message_type: :outgoing, content: 'test', content_type: 'input_select',
                  content_attributes: {
                    'items' => [{ 'title' => 'test', 'value' => 'test' }],
                    :message_payload => { 'content_type' => 'question',
                                          'content' =>
                        { 'video' => 'https://media.giphy.com/media/3oKIPsx2VAYAgEHC12/giphy.mp4',
                          'buttons' =>
                          [
                            { 'content_type' => 'button',
                              'content' => { 'title' => 'test', 'accepts' => ['teste'] } }
                          ],
                          'title' => 'What would you like to do today?' } }
                  },
                  conversation: create(:conversation, inbox: telegram_channel.inbox, additional_attributes: { 'chat_id' => '123' })
      )

      stub_request(:post, "https://api.telegram.org/bot#{telegram_channel.bot_token}/sendVideo")
        .with(
          body: 'chat_id=123&caption=test&video=https%3A%2F%2Fmedia.giphy.com%2Fmedia%2F3oKIPsx2VAYAgEHC12%2Fgiphy.mp4&reply_markup=%7B%22one_time_keyboard%22%3Atrue%2C%22inline_keyboard%22%3A%5B%5B%7B%22text%22%3A%22test%22%2C%22callback_data%22%3A%22test%22%7D%5D%5D%7D'
        )
        .to_return(
          status: 200,
          body: { result: { message_id: 'telegram_123' } }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )

      expect(telegram_channel.send_message_on_telegram(message)).to eq('telegram_123')
    end

    it 'send message with reply_markup and document' do
      message = create(
        :message, message_type: :outgoing, content: 'test', content_type: 'input_select',
                  content_attributes: {
                    'items' => [{ 'title' => 'test', 'value' => 'test' }],
                    :message_payload => { 'content_type' => 'question',
                                          'content' =>
                        { 'document' => 'https://nyphil.org/~/media/pdfs/program-notes/1819/Brahms-Symphony-No-4.pdf',
                          'buttons' =>
                          [
                            { 'content_type' => 'button',
                              'content' => { 'title' => 'test', 'accepts' => ['teste'] } }
                          ],
                          'title' => 'What would you like to do today?' } }
                  },
                  conversation: create(:conversation, inbox: telegram_channel.inbox, additional_attributes: { 'chat_id' => '123' })
      )

      stub_request(:post, "https://api.telegram.org/bot#{telegram_channel.bot_token}/sendDocument")
        .with(
          body: 'chat_id=123&caption=test&document=https%3A%2F%2Fnyphil.org%2F~%2Fmedia%2Fpdfs%2Fprogram-notes%2F1819%2FBrahms-Symphony-No-4.pdf&reply_markup=%7B%22one_time_keyboard%22%3Atrue%2C%22inline_keyboard%22%3A%5B%5B%7B%22text%22%3A%22test%22%2C%22callback_data%22%3A%22test%22%7D%5D%5D%7D'
        )
        .to_return(
          status: 200,
          body: { result: { message_id: 'telegram_123' } }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )

      expect(telegram_channel.send_message_on_telegram(message)).to eq('telegram_123')
    end
  end
end
