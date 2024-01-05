class Api::V1::Accounts::InboxesController < Api::V1::Accounts::BaseController
  include Api::V1::InboxesHelper
  before_action :fetch_inbox, except: [:index, :create, :refresh_token]
  before_action :fetch_agent_bot, only: [:set_agent_bot]
  before_action :validate_limit, only: [:create]
  # we are already handling the authorization in fetch inbox
  before_action :check_authorization, except: [:show, :refresh_token]

  def index
    @inboxes = policy_scope(Current.account.inboxes.order_by_name.includes(:channel, { avatar_attachment: [:blob] }))
  end

  def show; end

  # Deprecated: This API will be removed in 2.7.0
  def assignable_agents
    @assignable_agents = @inbox.assignable_agents
  end

  def campaigns
    @campaigns = @inbox.campaigns
  end

  def avatar
    @inbox.avatar.attachment.destroy! if @inbox.avatar.attached?
    head :ok
  end

  def create
    ActiveRecord::Base.transaction do
      channel = create_channel
      @inbox = Current.account.inboxes.build(
        {
          name: inbox_name(channel),
          channel: channel
        }.merge(
          permitted_params.except(:channel)
        )
      )
      @inbox.save!
    end
  end

  def update
    @inbox.update!(permitted_params.except(:channel))
    update_inbox_working_hours
    update_channel if channel_update_required?
  end

  def agent_bot
    @agent_bot = @inbox.agent_bot
  end

  def set_agent_bot
    if @agent_bot
      agent_bot_inbox = @inbox.agent_bot_inbox || AgentBotInbox.new(inbox: @inbox)
      agent_bot_inbox.agent_bot = @agent_bot
      agent_bot_inbox.save!
    elsif @inbox.agent_bot_inbox.present?
      @inbox.agent_bot_inbox.destroy!
    end
    head :ok
  end

  def destroy
    ::DeleteObjectJob.perform_later(@inbox) if @inbox.present?
    render status: :ok, json: { message: I18n.t('messages.inbox_deletetion_response') }
  end

  def template
    fetch_channel
    @template = permit_template_params
    attach_image_to_template if params[:header_type] == "image"
    response = @template[:id].nil? ? @channel.create_template(@template) : @channel.edit_template(@template)
    if response.success?
      render status: :ok, json: { message: I18n.t('messages.inbox_deletetion_response') }
    else 
      render status: :ok, json: { error: response["error"]["error_user_msg"] }
    end
  end

  def delete_template
    fetch_channel
    response = @channel.delete_template(params[:name])
    if response.success?
      render status: :ok, json: { message: I18n.t('messages.inbox_deletetion_response') }
    else 
      render status: :ok, json: { error: response["error"]["error_user_msg"] }
    end
  end

  def refresh_token
    begin
      unless params[:refreshed]
        raise " Token couldn't be refreshed Channel: #{inbox.name}"
      end
    rescue => e
      pp 'couldn\'t refresh token'
      Sentry.capture_exception(e)
      return
    end
    inbox = Current.account.inboxes.find(params[:id])
    channel = inbox.channel
    channel.provider_config["refreshed_at"] = Time.current
    channel.save!
  end

  def update_profile_picture
    fetch_channel
    response = @channel.update_profile_picture(params[:image], params[:profile])
    if response.success?
      @channel.profile_picture.attach(params[:image]) if params[:image].present?
      render status: :ok , json: {message: "OK"}
    else 
      render status: :ok, json: { error: response["error"]["message"] }
    end
  end
  private

  def fetch_inbox
    @inbox = Current.account.inboxes.find(params[:id])
    authorize @inbox, :show?
  end

  def fetch_agent_bot
    @agent_bot = AgentBot.find(params[:agent_bot]) if params[:agent_bot]
  end

  def create_channel
    return unless %w[web_widget api email line telegram whatsapp sms].include?(permitted_params[:channel][:type])

    account_channels_method.create!(permitted_params(channel_type_from_params::EDITABLE_ATTRS)[:channel].except(:type))
  end

  def update_inbox_working_hours
    @inbox.update_working_hours(params.permit(working_hours: Inbox::OFFISABLE_ATTRS)[:working_hours]) if params[:working_hours]
  end

  def update_channel
    channel_attributes = get_channel_attributes(@inbox.channel_type)
    return if permitted_params(channel_attributes)[:channel].blank?

    validate_and_update_email_channel(channel_attributes) if @inbox.inbox_type == 'Email'

    reauthorize_and_update_channel(channel_attributes)
    update_channel_feature_flags
  end

  def channel_update_required?
    permitted_params(get_channel_attributes(@inbox.channel_type))[:channel].present?
  end

  def validate_and_update_email_channel(channel_attributes)
    validate_email_channel(channel_attributes)
  rescue StandardError => e
    render json: { message: e }, status: :unprocessable_entity and return
  end

  def reauthorize_and_update_channel(channel_attributes)
    @inbox.channel.reauthorized! if @inbox.channel.respond_to?(:reauthorized!)
    @inbox.channel.update!(permitted_params(channel_attributes)[:channel])
  end

  def update_channel_feature_flags
    return unless @inbox.web_widget?
    return unless permitted_params(Channel::WebWidget::EDITABLE_ATTRS)[:channel].key? :selected_feature_flags

    @inbox.channel.selected_feature_flags = permitted_params(Channel::WebWidget::EDITABLE_ATTRS)[:channel][:selected_feature_flags]
    @inbox.channel.save!
  end

  def inbox_attributes
    [:name, :avatar, :greeting_enabled, :greeting_message, :enable_email_collect, :csat_survey_enabled,
     :enable_auto_assignment, :working_hours_enabled, :out_of_office_message, :timezone, :allow_messages_after_resolved,
     :lock_to_single_conversation, :portal_id]
  end

  def permitted_params(channel_attributes = [])
    # We will remove this line after fixing https://linear.app/chatwoot/issue/CW-1567/null-value-passed-as-null-string-to-backend
    params.each { |k, v| params[k] = params[k] == 'null' ? nil : v }

    params.permit(
      *inbox_attributes,
      channel: [:type, *channel_attributes]
    )
  end

  def channel_type_from_params
    {
      'web_widget' => Channel::WebWidget,
      'api' => Channel::Api,
      'email' => Channel::Email,
      'line' => Channel::Line,
      'telegram' => Channel::Telegram,
      'whatsapp' => Channel::Whatsapp,
      'sms' => Channel::Sms
    }[permitted_params[:channel][:type]]
  end

  def get_channel_attributes(channel_type)
    if channel_type.constantize.const_defined?(:EDITABLE_ATTRS)
      channel_type.constantize::EDITABLE_ATTRS.presence
    else
      []
    end
  end

  def permit_template_params
    template_hash = JSON.parse(params.require(:template))
    ActionController::Parameters.new(template_hash).permit(
      :id,
      :category,
      :language,
      :name,
      components: [
        :format,
        :type,
        :text,
        buttons: [
          :text,
          :type,
          :phone_number,
          :url,
          example: []
        ]
      ]
    )
  end

  def fetch_channel
    @channel = @inbox.channel
  end

  def attach_image_to_template
    image = @channel.template_images.attach(params[:image])
    url = url_for(@channel.template_images.last)
    handler = @channel.upload_media(params[:image])
    @template["components"].prepend({"type": "HEADER",
      "format": "IMAGE", "example": {
        "header_handle": [handler['h']]
      }})
  end
end

Api::V1::Accounts::InboxesController.prepend_mod_with('Api::V1::Accounts::InboxesController')
