# frozen_string_literal: true

module WlAi
  class IncomingReplyJob < ApplicationJob
    queue_as :default

    def perform(conversation_id, assistant_id)
      conversation = Conversation.find_by(id: conversation_id)
      assistant = WlAiAssistant.find_by(id: assistant_id)
      return if conversation.blank? || assistant.blank?

      inbox = conversation.inbox
      return if inbox.respond_to?(:captain_active?) && inbox.captain_active?
      return unless inbox.wl_ai_assistant&.id == assistant.id

      WlAi::ConversationReplyService.new(conversation: conversation, assistant: assistant).call
    end
  end
end
