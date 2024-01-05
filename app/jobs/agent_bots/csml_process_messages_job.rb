class AgentBots::CsmlProcessMessagesJob < ApplicationJob
  queue_as :high

  def perform(message, conversation, agent_bot)
    Integrations::Csml::ProcessMessage.new(
      message: message,
      conversation: conversation,
      agent_bot: agent_bot
    ).perform
  end
end
