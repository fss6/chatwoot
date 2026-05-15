# frozen_string_literal: true

module WlBotFlows
  module Actions
    class WaitSeconds < Base
      def call
        seconds = @data[:seconds].to_i
        seconds = 1 if seconds <= 0
        Result.wait(wait_seconds: seconds)
      end
    end
  end
end
