# frozen_string_literal: true

module WlBotFlows
  module Actions
    class WaitForContactMessage < Base
      DEFAULT_TIMEOUT = 300

      def call
        timeout = resolve_timeout
        @session.update!(
          status: :waiting_contact_message,
          waiting_since: Time.current,
          timeout_at: Time.current + timeout.seconds
        )
        WlBotFlows::SessionTimeoutJob.set(wait: timeout.seconds).perform_later(@session.id)
        Result.wait
      end

      private

      def resolve_timeout
        setting = @data[:timeout]
        return DEFAULT_TIMEOUT if setting.blank? || setting == 'default'

        setting.to_i.positive? ? setting.to_i : DEFAULT_TIMEOUT
      end
    end
  end
end
