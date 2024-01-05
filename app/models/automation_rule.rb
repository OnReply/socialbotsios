# == Schema Information
#
# Table name: automation_rules
#
#  id          :bigint           not null, primary key
#  actions     :jsonb            not null
#  active      :boolean          default(TRUE), not null
#  conditions  :jsonb            not null
#  description :text
#  event_name  :string           not null
#  name        :string           not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  account_id  :bigint           not null
#
# Indexes
#
#  index_automation_rules_on_account_id  (account_id)
#
class AutomationRule < ApplicationRecord
  include Rails.application.routes.url_helpers

  belongs_to :account
  has_many_attached :files
  has_one_attached :image

  validate :json_conditions_format
  validate :json_actions_format
  validate :query_operator_presence
  validates :account_id, presence: true
  validate :send_whatsapp_template_conditions

  scope :active, -> { where(active: true) }

  CONDITIONS_ATTRS = %w[content email country_code status message_type browser_language assignee_id team_id referer city company inbox_id
                        mail_subject phone_number priority conversation_language].freeze
  ACTIONS_ATTRS = %w[send_message add_label send_email_to_team assign_team assign_agent send_webhook_event mute_conversation send_attachment
                     change_status resolve_conversation snooze_conversation open_conversation close_conversation change_priority send_email_transcript send_whatsapp_template].freeze

  def file_base_data
    files.map do |file|
      {
        id: file.id,
        automation_rule_id: id,
        file_type: file.content_type,
        account_id: account_id,
        file_url: url_for(file),
        blob_id: file.blob_id,
        filename: file.filename.to_s
      }
    end
  end

  private

  def json_conditions_format
    return if conditions.blank?

    attributes = conditions.map { |obj, _| obj['attribute_key'] }
    conditions = attributes - CONDITIONS_ATTRS
    conditions -= account.custom_attribute_definitions.pluck(:attribute_key)
    errors.add(:conditions, "Automation conditions #{conditions.join(',')} not supported.") if conditions.any?
  end

  def json_actions_format
    return if actions.blank?

    attributes = actions.map { |obj, _| obj['action_name'] }
    actions = attributes - ACTIONS_ATTRS

    errors.add(:actions, "Automation actions #{actions.join(',')} not supported.") if actions.any?
  end

  def query_operator_presence
    return if conditions.blank?

    operators = conditions.select { |obj, _| obj['query_operator'].nil? }
    errors.add(:conditions, 'Automation conditions should have query operator.') if operators.length > 1
  end

  def send_whatsapp_template_conditions
    (errors.add(:wrong_conditions, 'bla bla bla')&& return) if actions.count { |action| action['action_name'] == 'send_whatsapp_template' } > 1
    if actions.any? { |action| action['action_name'] == 'send_whatsapp_template' }
      (errors.add(:wrong_conditions, 'Select Inbox ') && return) unless conditions.any? { |condition| condition['attribute_key'] == 'inbox_id' }
      if event_name == 'message_created'
        (errors.add(:select_message_type, 'Select Message type') && return) unless conditions.any? { |condition| condition['attribute_key'] == 'message_type' }
        if conditions.any? { |condition| condition['values'].include?('incoming') } &&
          conditions.any? { |condition| condition['values'].include?('outgoing') }
          errors.add(:infinite_loop, 'These condition will create infinite loop')
          return
       end
      end
    end
  end
end

AutomationRule.include_mod_with('Audit::AutomationRule')
