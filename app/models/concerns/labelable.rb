module Labelable
  extend ActiveSupport::Concern

  included do
    acts_as_taggable_on :labels
  end

  def update_labels(labels = nil)
    update!(label_list: labels)
    sync_contact_conversations_labels()
  end

  def add_labels(new_labels = nil)
    new_labels << labels
    update!(label_list: new_labels)
    sync_contact_conversations_labels()
  end

  def labels_list_array
    labels.pluck(:name)
  end

  def labels_list
    labels_list_array.join(',')
  end

  def sync_contact_conversations_labels()
    Conversations::ContactSyncLabelsJob.set(wait: 5.seconds).perform_later(self.contact.id) if self.is_a?(Conversation)
  end
end
