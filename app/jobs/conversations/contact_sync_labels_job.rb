class Conversations::ContactSyncLabelsJob < ApplicationJob
  queue_as :low

  def perform(contact_id)
    contact = Contact.find(contact_id)

    conversations_tags = []
    contact.conversations.find_each(batch_size: 50) do |conversation|
      conversations_tags = (conversations_tags + conversation.labels_list_array).flatten.uniq
    end

    contact.update_labels(conversations_tags)
  end
end
