module Facebook::InteractiveMessages
  private

  def send_interactive_messages
    send_message_to_facebook fb_buttons_message_params
  end

  def fb_buttons_message_params
    {
      recipient: { id: contact.get_source_id(inbox.id) },
      message: { text: message.content, quick_replies: build_buttons },
      messaging_type: 'RESPONSE'
    }
  end

  def build_buttons
    message.content_attributes['items'].map do |item|
      {
        'content_type': 'text',
        'title': item['title'],
        'payload': item['value']
      }
    end
  end
end
