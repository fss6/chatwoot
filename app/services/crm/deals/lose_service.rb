module Crm
  module Deals
    class LoseService
      def initialize(deal:, actor:, lost_reason:)
        @deal = deal
        @actor = actor
        @lost_reason = lost_reason
      end

      def perform
        raise ArgumentError, 'lost_reason is required' if @lost_reason.blank?

        lost_stage = @deal.pipeline.stages.find_by(stage_type: :lost)

        Crm::Deal.transaction do
          attrs = { status: :lost, closed_at: Time.current, lost_reason: @lost_reason }
          attrs[:stage] = lost_stage if lost_stage
          @deal.update!(attrs)

          Crm::Activities::CreateService.new(
            account: @deal.account,
            deal: @deal,
            actor: @actor,
            action: 'deal.lost',
            metadata: { lost_reason: @lost_reason }
          ).perform
        end

        @deal.reload
      end
    end
  end
end
