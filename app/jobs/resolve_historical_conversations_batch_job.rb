class ResolveHistoricalConversationsBatchJob < ApplicationJob
  queue_as :default

  def perform(conversation_ids)
    conversations = Conversation.where(id: conversation_ids)
    return unless conversations.exists?

    # Get the current time
    current_time = Time.current

    # Process conversations in batches to avoid memory issues
    conversations.in_batches(of: 20) do |batch|
      # Update conversations that haven't been modified since creation
      # Use proper PostgreSQL interval syntax
      batch.where('updated_at <= created_at + interval \'5 minutes\'')
           .update_all(status: :resolved)

      # Log the results
      updated_count = batch.where('updated_at <= created_at + interval \'5 minutes\'').count
      skipped_count = batch.where('updated_at > created_at + interval \'5 minutes\'').count

      Rails.logger.info "[HISTORICAL_RESOLUTION] Batch processed: #{updated_count} resolved, #{skipped_count} skipped"
    end
  end
end
