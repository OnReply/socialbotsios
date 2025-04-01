class ResolveHistoricalConversationsBatchJob < ApplicationJob
  queue_as :default

  def perform(conversation_ids)
    Rails.logger.info "[HISTORICAL_RESOLUTION] Starting batch job with #{conversation_ids.size} conversation IDs"

    conversations = Conversation.where(id: conversation_ids)
    return unless conversations.exists?

    Rails.logger.info "[HISTORICAL_RESOLUTION] Found #{conversations.count} conversations to process"

    # Get the current time
    current_time = Time.current

    # Process conversations in batches to avoid memory issues
    batch_number = 1
    conversations.in_batches(of: 20) do |batch|
      Rails.logger.info "[HISTORICAL_RESOLUTION] Processing sub-batch #{batch_number} with #{batch.count} conversations"

      # Update conversations that haven't been modified since creation
      # Use proper PostgreSQL interval syntax
      batch.where('updated_at <= created_at + interval \'5 minutes\'')
           .update_all(status: :resolved)

      # Log the results
      updated_count = batch.where('updated_at <= created_at + interval \'5 minutes\'').count
      skipped_count = batch.where('updated_at > created_at + interval \'5 minutes\'').count

      Rails.logger.info "[HISTORICAL_RESOLUTION] Sub-batch #{batch_number} complete: #{updated_count} resolved, #{skipped_count} skipped"
      batch_number += 1
    end

    Rails.logger.info '[HISTORICAL_RESOLUTION] Completed processing all conversations in batch'
  end
end
