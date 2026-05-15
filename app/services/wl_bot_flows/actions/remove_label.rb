# frozen_string_literal: true

module WlBotFlows
  module Actions
    class RemoveLabel < Base
      def call
        return Result.failed('Conversation not found') if conversation.blank?

        labels = Array(@data[:labels]).map(&:to_s)
        action_service.remove_label(labels)
        Result.continue
      rescue StandardError => e
        Result.failed(e.message)
      end
    end
  end
end
