module Integrations::Csml::ProcessFileMessage
  include FileTypeHelper

  def process_file_messages(message_payload, conversation)
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

    prepare_file_attachment(message_payload, message, conversation.account_id)
    message.save!
  end

  def prepare_file_attachment(message_payload, message, account_id)
    attachment_url = message_payload['content']['url']
    attachment_file = Down.download(attachment_url)

    attachment_params = { file_type: file_type(attachment_file.content_type), account_id: account_id }
    attachment = message.attachments.new(attachment_params)  
    attachment.file.attach(
      io: attachment_file,
      filename: attachment_file.original_filename,
      content_type: attachment_file.content_type
    )
  end
end