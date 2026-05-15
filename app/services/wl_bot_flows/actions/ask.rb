# frozen_string_literal: true

module WlBotFlows
  module Actions
    class Ask < Base
      DEFAULT_TIMEOUT = 300

      def call
        send_question_message
        enter_wait_state
      end

      private

      def send_question_message
        return if conversation.blank?

        text = @interpolator.interpolate(@data[:text].to_s)
        params = { content: text, private: false, message_type: 'outgoing' }
        Messages::MessageBuilder.new(@agent_bot, conversation, params).perform
      end

      def enter_wait_state
        timeout = resolve_timeout
        @session.update!(
          status: :waiting_contact_message,
          waiting_since: Time.current,
          timeout_at: Time.current + timeout.seconds
        )
        WlBotFlows::SessionTimeoutJob.set(wait: timeout.seconds).perform_later(@session.id)
        Result.wait
      end

      def resolve_timeout
        setting = @data[:timeout]
        return DEFAULT_TIMEOUT if setting.blank? || setting == 'default'

        setting.to_i.positive? ? setting.to_i : DEFAULT_TIMEOUT
      end
    end
  end
end
