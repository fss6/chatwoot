# frozen_string_literal: true

module WlBotFlows
  class ActionRunner
    ACTION_CLASSES = {
      'send_message' => Actions::SendMessage,
      'wait_for_contact_message' => Actions::WaitForContactMessage,
      'wait_seconds' => Actions::WaitSeconds,
      'condition' => Actions::Condition,
      'go_to_group' => Actions::GoToGroup,
      'transfer_to_team' => Actions::TransferToTeam,
      'assign_agent' => Actions::AssignAgent,
      'finish_conversation' => Actions::FinishConversation,
      'add_label' => Actions::AddLabel,
      'remove_label' => Actions::RemoveLabel,
      'set_custom_attribute' => Actions::SetCustomAttribute,
      'send_webhook' => Actions::SendWebhook,
      'ask' => Actions::Ask
    }.freeze

    def initialize(action:, session:, context:, flow:, agent_bot:)
      @action = action
      @session = session
      @context = context
      @flow = flow
      @agent_bot = agent_bot
    end

    def call
      klass = ACTION_CLASSES[@action['type'].to_s]
      return Actions::Result.failed("Unknown action type: #{@action['type']}") if klass.blank?

      klass.new(
        action: @action,
        session: @session,
        context: @context,
        flow: @flow,
        agent_bot: @agent_bot
      ).call
    end
  end
end
