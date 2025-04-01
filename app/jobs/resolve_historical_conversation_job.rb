class ResolveHistoricalConversationJob < ApplicationJob
  queue_as :default

  def perform(conversation_id)
    conversation = Conversation.find_by(id: conversation_id)
    return unless conversation

    # Only resolve if the conversation hasn't been updated since it was created
    # This prevents resolving conversations that agents have interacted with
    if conversation.updated_at <= conversation.created_at + 5.minutes
      conversation.update(status: :resolved)
      Rails.logger.info "[HISTORICAL_RESOLUTION] Resolved conversation #{conversation_id}"
    else
      Rails.logger.info "[HISTORICAL_RESOLUTION] Skipped resolution for conversation #{conversation_id} as it has been updated"
    end
  end
end
