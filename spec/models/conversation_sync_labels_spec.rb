# frozen_string_literal: true

require 'rails_helper'
include ActiveJob::TestHelper

RSpec.describe Conversation do
  describe '#update_labels' do
    let(:account) { create(:account) }
    let(:contact) { create(:contact, account: account) }    
    let(:conversation) { create(:conversation, account: account, contact: contact) }
    let(:conversation_2) { create(:conversation, account: account, contact: contact) }
    let(:agent) do
      create(:user, email: 'agent@example.com', account: account, role: :agent)
    end
    let(:first_label) { create(:label, account: account) }
    let(:second_label) { create(:label, account: account) }
    let(:third_label) { create(:label, account: account) }
    let(:fourth_label) { create(:label, account: account) }

    before do
      conversation
      Current.user = agent

      first_label
      second_label
      third_label
      fourth_label
    end

    it 'adds one label to conversation' do
      perform_enqueued_jobs(only: Conversations::ContactSyncLabelsJob) do
        labels = [first_label].map(&:title)
        conversation.update_labels(labels)
        expect(conversation.contact.label_list).to match_array(labels)
      end
    end

    it 'change labels' do
      perform_enqueued_jobs(only: Conversations::ContactSyncLabelsJob) do
        labels = [first_label].map(&:title)
        conversation.update_labels(labels)
        new_labels = [second_label, third_label].map(&:title)
        conversation.update_labels(new_labels)
        expect(conversation.contact.reload.label_list).to match_array(new_labels)
      end
    end

    it 'contacts should merge conversation tags' do
      perform_enqueued_jobs(only: Conversations::ContactSyncLabelsJob) do
        labels_conversation_1 = [first_label].map(&:title)
        conversation.update_labels(labels_conversation_1)
        labels_conversation_2 = [second_label, third_label].map(&:title)
        conversation_2.update_labels(labels_conversation_2)
        expect(conversation.contact.reload.label_list).to match_array(labels_conversation_1 + labels_conversation_2)
      end
    end
  end
end
