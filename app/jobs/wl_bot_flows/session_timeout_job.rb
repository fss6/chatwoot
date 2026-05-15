# frozen_string_literal: true

module WlBotFlows
  class SessionTimeoutJob < ApplicationJob
    queue_as :default

    def perform(session_id)
      session = WlBotSession.find_by(id: session_id)
      return if session.blank?
      return unless session.waiting_contact_message?
      return if session.timeout_at.blank? || session.timeout_at > Time.current

      timeout_group_id = resolve_timeout_group(session)
      if timeout_group_id.present?
        session.update!(
          status: :active,
          waiting_since: nil,
          timeout_at: nil,
          current_group_id: timeout_group_id,
          current_action_index: 0
        )
      else
        session.update!(status: :active, waiting_since: nil, timeout_at: nil)
      end

      agent_bot = session.wl_bot_flow.agent_bot
      return if agent_bot.blank?

      payload = {
        event: 'wl_bot_flow_continue',
        conversation: {
          id: session.chatwoot_conversation_id,
          account_id: session.chatwoot_account_id
        },
        account: { id: session.chatwoot_account_id },
        inbox: { id: session.wl_bot_flow.inbox_id }
      }

      ProcessEventJob.perform_later(agent_bot.id, payload)
    end

    private

    def resolve_timeout_group(session)
      flow = session.wl_bot_flow.published_json&.deep_stringify_keys
      return nil if flow.blank?

      group = (flow['groups'] || []).find { |g| g['id'] == session.current_group_id }
      return nil if group.blank?

      action = (group['actions'] || [])[session.current_action_index]
      return nil unless action&.dig('type') == 'ask'

      action.dig('data', 'timeout_group_id').presence
    end
  end
end
