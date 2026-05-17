module Crm
  module Deals
    class CreateService
      def initialize(account:, params:, actor:)
        @account = account
        @params = params
        @actor = actor
      end

      def perform
        pipeline = find_pipeline
        stage = find_stage(pipeline)
        validate_conversation_contact!

        deal = nil
        Crm::Deal.transaction do
          deal = @account.crm_deals.create!(
            deal_attributes.merge(
              pipeline: pipeline,
              stage: stage,
              position: next_position(stage),
              status: stage_status(stage)
            )
          )
          Crm::Activities::CreateService.new(
            account: @account,
            deal: deal,
            actor: @actor,
            action: 'deal.created',
            metadata: { title: deal.title }
          ).perform
        end
        deal
      end

      private

      def deal_attributes
        @params.slice(
          :title, :description, :amount, :currency, :source, :lead_temperature,
          :expected_close_date, :contact_id, :conversation_id, :assigned_user_id
        )
      end

      def find_pipeline
        if @params[:pipeline_id].present?
          @account.crm_pipelines.find(@params[:pipeline_id])
        else
          Crm::Pipelines::DefaultSetupService.new(account: @account).perform
        end
      end

      def find_stage(pipeline)
        if @params[:stage_id].present?
          pipeline.stages.find(@params[:stage_id])
        else
          pipeline.stages.active.where(stage_type: :open).ordered.first || pipeline.stages.active.ordered.first
        end
      end

      def validate_conversation_contact!
        return if @params[:conversation_id].blank?

        conversation = @account.conversations.find(@params[:conversation_id])
        return if conversation.contact_id == @params[:contact_id].to_i

        raise ArgumentError, 'Contact does not match conversation'
      end

      def next_position(stage)
        (stage.deals.maximum(:position) || -1) + 1
      end

      def stage_status(stage)
        return :won if stage.won?
        return :lost if stage.lost?

        :open
      end
    end
  end
end
