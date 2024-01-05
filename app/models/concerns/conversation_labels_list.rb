module ConversationLabelsList
  extend ActiveSupport::Concern

  def conversations_labels_list
    labels_list = []
    conversations.each do | conversation |
      labels_list.concat(conversation.labels_list_array)
    end
    labels_list.uniq.join(',')
  end
end
