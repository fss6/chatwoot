# frozen_string_literal: true

module WlBotFlows
  module Actions
    class Base
      def initialize(action:, session:, context:, flow:, agent_bot:)
        @action = action.with_indifferent_access
        @data = (@action[:data] || {}).with_indifferent_access
        @session = session
        @context = context
        @flow = flow
        @agent_bot = agent_bot
        @interpolator = VariableInterpolator.new(session: session, context: context)
      end

      def call
        raise NotImplementedError
      end

      private

      def conversation
        @conversation ||= @session.conversation
      end

      def action_service
        @action_service ||= ActionService.new(conversation)
      end
    end
  end
end
