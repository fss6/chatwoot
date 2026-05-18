module Crm
  module Deals
    class MoveService
      def initialize(deal:, stage:, position:, actor:)
        @deal = deal
        @stage = stage
        @position = position
        @actor = actor
      end

      def perform
        old_stage = @deal.stage

        Crm::Deal.transaction do
          @deal.update!(stage: @stage, position: @position)
          apply_status_from_stage!
          create_activity!(old_stage)
        end

        @deal.reload
      end

      private

      def apply_status_from_stage!
        if @stage.won?
          @deal.update!(status: :won, closed_at: Time.current, lost_reason: nil)
        elsif @stage.lost?
          if @deal.open?
            raise ArgumentError, 'use lose action to mark deal as lost with a reason'
          end

          @deal.update!(status: :lost, closed_at: Time.current) unless @deal.lost?
        elsif @deal.won? || @deal.lost?
          @deal.update!(status: :open, closed_at: nil, lost_reason: nil)
        end
      end

      def create_activity!(old_stage)
        Crm::Activities::CreateService.new(
          account: @deal.account,
          deal: @deal,
          actor: @actor,
          action: 'deal.stage_changed',
          metadata: {
            from_stage_id: old_stage.id,
            to_stage_id: @stage.id,
            from_stage_name: old_stage.name,
            to_stage_name: @stage.name
          }
        ).perform
      end
    end
  end
end
