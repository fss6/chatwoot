# frozen_string_literal: true

module WlBotFlows
  module Actions
    class GoToGroup < Base
      def call
        target = @data[:target_group_id]
        return Result.failed('target_group_id is required') if target.blank?

        Result.go_to(target)
      end
    end
  end
end
