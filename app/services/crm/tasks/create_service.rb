module Crm
  module Tasks
    class CreateService
      def initialize(account:, params:, actor:)
        @account = account
        @params = params
        @actor = actor
      end

      def perform
        task = @account.crm_tasks.create!(@params)

        Crm::Activities::CreateService.new(
          account: @account,
          deal: task.deal,
          contact: task.contact,
          conversation: task.conversation,
          actor: @actor,
          action: 'task.created',
          metadata: { task_id: task.id, title: task.title }
        ).perform if task.deal.present?

        task
      end
    end
  end
end
