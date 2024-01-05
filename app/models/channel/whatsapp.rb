# == Schema Information
#
# Table name: channel_whatsapp
#
#  id                             :bigint           not null, primary key
#  message_templates              :jsonb
#  message_templates_last_updated :datetime
#  phone_number                   :string           not null
#  provider                       :string           default("default")
#  provider_config                :jsonb
#  created_at                     :datetime         not null
#  updated_at                     :datetime         not null
#  account_id                     :integer          not null
#
# Indexes
#
#  index_channel_whatsapp_on_phone_number  (phone_number) UNIQUE
#

class Channel::Whatsapp < ApplicationRecord
  include Channelable
  include Reauthorizable

  self.table_name = 'channel_whatsapp'
  EDITABLE_ATTRS = [:phone_number, :provider, { provider_config: {} }].freeze

  # default at the moment is 360dialog lets change later.
  PROVIDERS = %w[default whatsapp_cloud].freeze
  before_validation :ensure_webhook_verify_token

  validates :provider, inclusion: { in: PROVIDERS }
  validates :phone_number, presence: true, uniqueness: true
  validate :validate_provider_config
  has_many_attached :template_images
  has_one_attached :profile_picture

  after_create :after_create_methods
  after_update :should_extend_token, if: :saved_change_to_provider_config?

  def name
    'Whatsapp'
  end

  def provider_service
    if provider == 'whatsapp_cloud'
      Whatsapp::Providers::WhatsappCloudService.new(whatsapp_channel: self)
    else
      Whatsapp::Providers::Whatsapp360DialogService.new(whatsapp_channel: self)
    end
  end

  def messaging_window_enabled?
    true
  end

  def mark_message_templates_updated
    # rubocop:disable Rails/SkipsModelValidations
    update_column(:message_templates_last_updated, Time.zone.now)
    # rubocop:enable Rails/SkipsModelValidations
  end

  def should_refresh_token?
    provider_config["last_refresh_at"] == nil || provider_config["last_refresh_at"].to_time < 1.day.ago
  end

  def update_profile_picture(image, profile) 
    if image.present?
      upload_id = provider_service.create_upload_session(image.size, image.content_type, image.original_filename.gsub(/\s+/, ""))
      handler =  provider_service.upload_file(image, image.content_type, upload_id["id"])
    end
    res = provider_service.update_whatsapp_profile(handler, profile)
    self.provider_config['profile'] = JSON.parse(profile)
    self.save! if res.success?
    res
  end

  def upload_media(image)
    upload_id = provider_service.create_upload_session(image.size, image.content_type, image.original_filename.gsub(/\s+/, ""))
    provider_service.upload_file(image, image.content_type, upload_id["id"])
  end

  def hit_webhook
    url = ENV.fetch('WHATSAPP_NEW_INBOX_URL', nil)
    return unless url.present?
    HTTParty.post(
      url,
      headers: {'Content-Type' => 'application/json'},
      body: {account_id: self.account_id, inbox_id: self.inbox.id, provider_config: self.provider_config}.to_json
    )
  end

  delegate :send_message, to: :provider_service
  delegate :send_template, to: :provider_service
  delegate :sync_templates, to: :provider_service
  delegate :media_url, to: :provider_service
  delegate :api_headers, to: :provider_service
  delegate :create_template, to: :provider_service
  delegate :edit_template, to: :provider_service
  delegate :delete_template, to: :provider_service
  delegate :extend_token_life, to: :provider_service
  delegate :sync_token_expiry_date, to: :provider_service
  delegate :refresh_token, to: :provider_service
  delegate :get_expires_at, to: :provider_service
  delegate :hit_update_token_webhook, to: :provider_service

  private

  def ensure_webhook_verify_token
    provider_config['webhook_verify_token'] ||= SecureRandom.hex(16) if provider == 'whatsapp_cloud'
  end

  def validate_provider_config
    errors.add(:provider_config, 'Invalid Credentials') unless provider_service.validate_provider_config?
  end

  def after_create_methods
    if(provider == 'whatsapp_cloud')
      self.extend_token_life()
      provider_service.get_app_id()
    end
    self.sync_templates()
    Channels::Whatsapp::WebhookJob.perform_later(self.id)
  end

  def should_extend_token
    return unless provider == 'whatsapp_cloud'
    res = self.get_expires_at
    if (Time.at(res["data"]["expires_at"]).utc > 7.days.after) || (res["data"]["expires_at"] == 0)
      Channels::Whatsapp::UpdateApiKeyJob.perform_later(self.id)
      return
    end
    self.extend_token_life() if provider == 'whatsapp_cloud' && saved_changes['provider_config'][0]['api_key'] != saved_changes['provider_config'][1]['api_key']
  end
end
