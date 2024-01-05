class ActionService
  include EmailHelper

  def initialize(conversation)
    @conversation = conversation.reload
  end

  def mute_conversation(_params)
    @conversation.mute!
  end

  def snooze_conversation(_params)
    @conversation.snoozed!
  end

  def resolve_conversation(_params)
    @conversation.resolved!
  end

  def open_conversation(_params)
    @conversation.open!
  end

  def change_status(status)
    @conversation.update!(status: status[0])
  end

  def change_priority(priority)
    @conversation.update!(priority: (priority[0] == 'nil' ? nil : priority[0]))
  end

  def add_label(labels)
    return if labels.empty?

    @conversation.reload.add_labels(labels)
  end

  def assign_agent(agent_ids = [])
    return unless agent_belongs_to_inbox?(agent_ids)

    @agent = @account.users.find_by(id: agent_ids)

    @conversation.update!(assignee_id: @agent.id) if @agent.present?
  end

  def remove_label(labels)
    return if labels.empty?

    labels = @conversation.label_list - labels
    @conversation.update(label_list: labels)
  end

  def assign_team(team_ids = [])
    return unassign_team if team_ids[0].zero?
    return unless team_belongs_to_account?(team_ids)

    @conversation.update!(team_id: team_ids[0])
  end

  def remove_assigned_team(_params)
    @conversation.update!(team_id: nil)
  end

  def send_email_transcript(emails)
    emails = emails[0].gsub(/\s+/, '').split(',')

    emails.each do |email|
      email = parse_email_variables(@conversation, email)
      ConversationReplyMailer.with(account: @conversation.account).conversation_transcript(@conversation, email)&.deliver_later
    end
  end

  def send_whatsapp_template(_params)
    uploaded_file = nil
    if @rule.image.attached?
      image = Tempfile.new(["copy_", ".#{@rule.image.filename.extension}"])
      image.binmode
      image.write(@rule.image.download)
      image.close
      uploaded_file = ActionDispatch::Http::UploadedFile.new(
        tempfile: image,
        filename: 'copy.png',   # Provide a desired filename
        type: @rule.image.blob.content_type       # Provide the actual content type
      )
    end
    data = JSON.parse(_params.first)
    params = ActionController::Parameters.new(
      "content" => data["message"],
      "image" => uploaded_file,
      "template_params" => {
        "name" => data["templateParams"]["name"],
        "category" => data["templateParams"]["category"],
        "language" => data["templateParams"]["language"],
        "processed_params" => data["templateParams"]["processed_params"],
        "namespace" => "undefined"
      },
      "format" => "json",
      "controller" => "api/v1/accounts/conversations/messages",
      "action" => "create",
      "account_id" => @conversation.account_id,
      "conversation_id" => @conversation.id,
      "sender_type" => "AgentBot"
    )
    mb = Messages::MessageBuilder.new(nil, @conversation, params)
    @message = mb.perform
  end

  private

  def agent_belongs_to_inbox?(agent_ids)
    member_ids = @conversation.inbox.members.pluck(:user_id)
    assignable_agent_ids = member_ids + @account.administrators.ids

    assignable_agent_ids.include?(agent_ids[0])
  end

  def team_belongs_to_account?(team_ids)
    @account.team_ids.include?(team_ids[0])
  end

  def conversation_a_tweet?
    return false if @conversation.additional_attributes.blank?

    @conversation.additional_attributes['type'] == 'tweet'
  end
end
