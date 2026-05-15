# frozen_string_literal: true

module WlBotFlows
  module AgentBotListenerExtension
    def process_webhook_bot_event(agent_bot, payload)
      if wl_bot_flow_managed?(agent_bot)
        WlBotFlows::ProcessEventJob.perform_later(agent_bot.id, payload.deep_stringify_keys)
        return
      end

      super
    end

    private

    def wl_bot_flow_managed?(agent_bot)
      return false unless ENV.fetch('WL_BOT_FLOWS_ENABLED', 'true') == 'true'

      agent_bot.bot_config&.dig('managed_by') == 'wl_bot_flows'
    end
  end
end
