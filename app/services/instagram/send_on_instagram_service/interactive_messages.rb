module Instagram::SendOnInstagramService::InteractiveMessages
  def message_buttons_params
    buttons = message.content_attributes['items'].map do |item|
      {
        'content_type': 'text',
        'title': item['title'],
        'payload': item['value']
      }
    end

    params = {
      recipient: { id: contact.get_source_id(inbox.id) },
      messaging_type: 'RESPONSE',
      message: {
        text: message.content,
        quick_replies: buttons
      }
    }

    merge_human_agent_tag(params)
  end
end
