# frozen_string_literal: true

module WlBotFlows
  module Actions
    class Result
      STATUSES = %i[continue wait go_to_group finish transfer failed].freeze

      attr_reader :status, :target_group_id, :error, :wait_seconds

      def initialize(status:, target_group_id: nil, error: nil, wait_seconds: nil)
        @status = status
        @target_group_id = target_group_id
        @error = error
        @wait_seconds = wait_seconds
      end

      def self.continue
        new(status: :continue)
      end

      def self.wait(wait_seconds: nil)
        new(status: :wait, wait_seconds: wait_seconds)
      end

      def self.go_to(target_group_id)
        new(status: :go_to_group, target_group_id: target_group_id)
      end

      def self.finish
        new(status: :finish)
      end

      def self.transfer
        new(status: :transfer)
      end

      def self.failed(error)
        new(status: :failed, error: error)
      end
    end
  end
end
