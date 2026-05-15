# frozen_string_literal: true

module WlBotFlows
  module Actions
    class FinishConversation < Base
      def call
        return Result.failed('Conversation not found') if conversation.blank?

        message = @data[:message]
        if message.present?
          text = @interpolator.interpolate(message.to_s)
          Messages::MessageBuilder.new(@agent_bot, conversation, { content: text, private: false }).perform
        end

        conversation.resolved!
        @session.update!(status: :finished, finished_at: Time.current)
        Result.finish
      rescue StandardError => e
        Result.failed(e.message)
      end
    end
  end
end
