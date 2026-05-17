module Crm
  module Activities
    class CreateService
      def initialize(account:, action:, actor: nil, deal: nil, contact: nil, conversation: nil, metadata: {})
        @account = account
        @action = action
        @actor = actor
        @deal = deal
        @contact = contact || deal&.contact
        @conversation = conversation || deal&.conversation
        @metadata = metadata
      end

      def perform
        Crm::Activity.create!(
          account: @account,
          deal: @deal,
          contact: @contact,
          conversation: @conversation,
          actor: @actor,
          action: @action,
          metadata: @metadata
        )
      end
    end
  end
end
