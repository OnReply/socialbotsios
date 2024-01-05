class Integrations::Csml::ProcessMessage < Integrations::BotProcessorService
  pattr_initialize [:message!, :conversation!, :agent_bot!]
  prepend Integrations::Csml::ProcessProductsMessage

  def perform
    create_messages(message, conversation)
  end

  private

  def csml_client
    @csml_client ||= CsmlEngine.new
  end

  def process_text_messages(message_payload, conversation)
    conversation.messages.create!(
      {
        message_type: :outgoing,
        account_id: conversation.account_id,
        inbox_id: conversation.inbox_id,
        content: message_payload['content']['text'],
        sender: agent_bot
      }
    )
  end

  def process_question_messages(message_payload, conversation)
    buttons = message_payload['content']['buttons'].map do |button|
      { title: button['content']['title'], value: button['content']['payload'] }
    end
    conversation.messages.create!(
      {
        message_type: :outgoing,
        account_id: conversation.account_id,
        inbox_id: conversation.inbox_id,
        content: message_payload['content']['title'],
        content_type: 'input_select',
        content_attributes: { items: buttons, message_payload: message_payload },
        sender: agent_bot
      }
    )
  end

  def prepare_attachment(message_payload, message, account_id)
    attachment_params = { file_type: :image, account_id: account_id }
    attachment_url = message_payload['content']['url']
    attachment = message.attachments.new(attachment_params)
    attachment_file = Down.download(attachment_url)
    attachment.file.attach(
      io: attachment_file,
      filename: attachment_file.original_filename,
      content_type: attachment_file.content_type
    )
  end

  def process_image_messages(message_payload, conversation)
    message = conversation.messages.new(
      {
        message_type: :outgoing,
        account_id: conversation.account_id,
        inbox_id: conversation.inbox_id,
        content: '',
        content_type: 'text',
        sender: agent_bot
      }
    )

    prepare_attachment(message_payload, message, conversation.account_id)
    message.save!
  end
end
