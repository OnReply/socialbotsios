class AgentBots::ValidateBotService
  pattr_initialize [:agent_bot]
  def perform
    return true unless agent_bot.bot_type == 'csml'

    validate_csml_bot
  end

  private

  def csml_client
    @csml_client ||= CsmlEngine.new
  end

  def csml_bot_payload
    {
      id: agent_bot[:name],
      name: agent_bot[:name],
      default_flow: 'Default',
      custom_components: {
        "WhatsappProducts": {
          "params": [
            {
              "catalog_id": {
                "required": true,
                "type": "String",
              }
            },
            {
              "header": {
                "required": true,
                "type": "String",
              }
            },
            {
              "products": {
                "required": true,
                "type": "Array",
              }
            },
            {
              "content": {
                "required": true,
                "type": "String",
              }
            },
            {
              "footer": {
                "required": false,
                "type": "String",
              }
            },
          ]
        }
      },
      flows: [
        {
          id: SecureRandom.uuid,
          name: 'Default',
          content: agent_bot.bot_config['csml_content'],
          commands: []
        }
      ]
    }
  end

  def validate_csml_bot
    response = csml_client.validate(csml_bot_payload)
    response.blank? || response['valid']
  rescue StandardError => e
    ChatwootExceptionTracker.new(e, account: agent_bot&.account).capture_exception
    false
  end
end
