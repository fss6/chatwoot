# frozen_string_literal: true

module WlBotFlows
  class SessionResolver
    def initialize(agent_bot:, context:)
      @agent_bot = agent_bot
      @context = context
    end

    def call
      flow = resolve_flow
      return nil if flow.blank? || !flow.published?

      session = WlBotSession.find_or_initialize_by(
        chatwoot_account_id: @context.account_id,
        chatwoot_conversation_id: @context.conversation_id
      )

      if session.new_record?
        session.assign_attributes(
          wl_bot_flow: flow,
          chatwoot_contact_id: @context.contact_id,
          current_group_id: flow.published_json['entry_group_id'],
          current_action_index: 0,
          status: :active,
          variables: {}
        )
        session.save!
      elsif session.wl_bot_flow_id != flow.id
        reset_session!(session, flow)
      end

      session
    end

    private

    def resolve_flow
      flow_id = @agent_bot.bot_config&.dig('wl_bot_flow_id')
      return nil if flow_id.blank?

      WlBotFlow.find_by(id: flow_id, agent_bot_id: @agent_bot.id, status: :published)
    end

    def reset_session!(session, flow)
      session.update!(
        wl_bot_flow: flow,
        current_group_id: flow.published_json['entry_group_id'],
        current_action_index: 0,
        status: :active,
        variables: {},
        waiting_since: nil,
        timeout_at: nil,
        finished_at: nil,
        transferred_at: nil
      )
    end
  end
end
