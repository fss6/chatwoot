module Crm
  module Tasks
    class CompleteService
      def initialize(task:, actor:)
        @task = task
        @actor = actor
      end

      def perform
        @task.update!(status: :done, completed_at: Time.current)

        Crm::Activities::CreateService.new(
          account: @task.account,
          deal: @task.deal,
          contact: @task.contact,
          conversation: @task.conversation,
          actor: @actor,
          action: 'task.completed',
          metadata: { task_id: @task.id, title: @task.title }
        ).perform if @task.deal.present?

        @task
      end
    end
  end
end
