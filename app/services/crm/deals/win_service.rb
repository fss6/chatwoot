module Crm
  module Deals
    class WinService
      def initialize(deal:, actor:)
        @deal = deal
        @actor = actor
      end

      def perform
        won_stage = @deal.pipeline.stages.find_by(stage_type: :won)

        Crm::Deal.transaction do
          attrs = { status: :won, closed_at: Time.current, lost_reason: nil }
          attrs[:stage] = won_stage if won_stage
          @deal.update!(attrs)

          Crm::Activities::CreateService.new(
            account: @deal.account,
            deal: @deal,
            actor: @actor,
            action: 'deal.won'
          ).perform
        end

        @deal.reload
      end
    end
  end
end
