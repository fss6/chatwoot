# frozen_string_literal: true

module WlBotFlows
  class ProcessEventJob < ApplicationJob
    queue_as :default

    def perform(agent_bot_id, payload)
      return unless wl_bot_flows_enabled?

      agent_bot = AgentBot.find_by(id: agent_bot_id)
      return unless wl_bot_flow_managed?(agent_bot)

      context = EventContext.new(payload)
      return unless processable_event?(context, agent_bot)

      inbox = Inbox.find_by(id: context.inbox_id)
      return if inbox.respond_to?(:captain_active?) && inbox.captain_active?

      session = SessionResolver.new(agent_bot: agent_bot, context: context).call
      return if session.blank?

      flow = session.wl_bot_flow
      return if flow.paused? || flow.archived?

      Runtime.new(
        bot_flow: flow,
        session: session,
        context: context,
        agent_bot: agent_bot,
        event_payload: payload
      ).call
    end

    private

    def wl_bot_flows_enabled?
      ENV.fetch('WL_BOT_FLOWS_ENABLED', 'true') == 'true'
    end

    def wl_bot_flow_managed?(agent_bot)
      agent_bot&.bot_config&.dig('managed_by') == 'wl_bot_flows'
    end

    def processable_event?(context, agent_bot)
      return false if context.agent_bot_sender?(agent_bot.id)

      return true if context.event_name == 'wl_bot_flow_continue'

      return false unless context.message_event?

      conversation = Conversation.find_by(
        id: context.conversation_id,
        account_id: context.account_id
      )
      return false if conversation.blank?

      conversation.pending?
    end
  end
end
