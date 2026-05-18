module Crm
  module Deals
    class UpdateService
      CLOSED_READONLY_KEYS = %i[
        title description amount currency lead_temperature assigned_user_id
        source expected_close_date
      ].freeze

      def initialize(deal:, params:, actor:)
        @deal = deal
        @params = params
        @actor = actor
      end

      def perform
        validate_closed_deal_updates!

        old_amount = @deal.amount
        old_assignee_id = @deal.assigned_user_id

        @deal.update!(@params)

        log_amount_change(old_amount) if @params.key?(:amount) && old_amount != @deal.amount
        log_assignee_change(old_assignee_id) if @params.key?(:assigned_user_id) && old_assignee_id != @deal.assigned_user_id

        Crm::Activities::CreateService.new(
          account: @deal.account,
          deal: @deal,
          actor: @actor,
          action: 'deal.updated'
        ).perform

        @deal
      end

      private

      def validate_closed_deal_updates!
        return unless @deal.won? || @deal.lost?

        forbidden = @params.keys.map(&:to_sym) & CLOSED_READONLY_KEYS
        return if forbidden.empty?

        raise ArgumentError, 'closed deals cannot be updated; reopen the deal first'
      end

      def log_amount_change(old_amount)
        Crm::Activities::CreateService.new(
          account: @deal.account,
          deal: @deal,
          actor: @actor,
          action: 'deal.amount_changed',
          metadata: { from: old_amount, to: @deal.amount }
        ).perform
      end

      def log_assignee_change(old_assignee_id)
        Crm::Activities::CreateService.new(
          account: @deal.account,
          deal: @deal,
          actor: @actor,
          action: 'deal.assignee_changed',
          metadata: { from_user_id: old_assignee_id, to_user_id: @deal.assigned_user_id }
        ).perform
      end
    end
  end
end
