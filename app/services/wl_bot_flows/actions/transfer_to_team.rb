# frozen_string_literal: true

module WlBotFlows
  module Actions
    class TransferToTeam < Base
      def call
        return Result.failed('Conversation not found') if conversation.blank?

        message = @data[:message]
        if message.present?
          text = @interpolator.interpolate(message.to_s)
          Messages::MessageBuilder.new(@agent_bot, conversation, { content: text, private: false }).perform
        end

        action_service.assign_team([@data[:team_id]])
        conversation.bot_handoff!
        @session.update!(status: :transferred_to_human, transferred_at: Time.current)
        Result.transfer
      rescue StandardError => e
        Result.failed(e.message)
      end
    end
  end
end
