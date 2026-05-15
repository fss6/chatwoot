# frozen_string_literal: true

Rails.application.config.to_prepare do
  listener = AgentBotListener
  extension = WlBotFlows::AgentBotListenerExtension
  listener.prepend(extension) unless listener.ancestors.include?(extension)
end
