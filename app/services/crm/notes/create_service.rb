module Crm
  module Notes
    class CreateService
      def initialize(deal:, actor:, content:)
        @deal = deal
        @actor = actor
        @content = content
      end

      def perform
        note = @deal.notes.create!(
          account: @deal.account,
          user: @actor,
          content: @content
        )

        Crm::Activities::CreateService.new(
          account: @deal.account,
          deal: @deal,
          actor: @actor,
          action: 'note.created',
          metadata: { note_id: note.id }
        ).perform

        note
      end
    end
  end
end
