# frozen_string_literal: true

module WlBotFlows
  module Actions
    class SendMessage < Base
      def call
        return Result.failed('Conversation not found') if conversation.blank?

        text = @interpolator.interpolate(@data[:text].to_s)
        params = { content: text, private: false, message_type: 'outgoing' }
        Messages::MessageBuilder.new(@agent_bot, conversation, params).perform
        Result.continue
      rescue StandardError => e
        Result.failed(e.message)
      end
    end
  end
end
