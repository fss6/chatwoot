module Crm
  module Pipelines
    class DefaultSetupService
      DEFAULT_PIPELINE = 'Vendas'.freeze
      DEFAULT_STAGES = [
        { name: 'Novo lead', stage_type: :open, position: 0 },
        { name: 'Contato iniciado', stage_type: :open, position: 1 },
        { name: 'Qualificado', stage_type: :open, position: 2 },
        { name: 'Proposta enviada', stage_type: :open, position: 3 },
        { name: 'Negociação', stage_type: :open, position: 4 },
        { name: 'Ganho', stage_type: :won, position: 5 },
        { name: 'Perdido', stage_type: :lost, position: 6 }
      ].freeze

      def initialize(account:)
        @account = account
      end

      def perform
        return @account.crm_pipelines.active.ordered.first if @account.crm_pipelines.active.exists?

        pipeline = @account.crm_pipelines.create!(name: DEFAULT_PIPELINE, position: 0, active: true)
        DEFAULT_STAGES.each do |attrs|
          pipeline.stages.create!(attrs.merge(account: @account, active: true))
        end
        pipeline
      end
    end
  end
end
