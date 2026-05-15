# frozen_string_literal: true

module WlAi
  # Performs WL AI bot handoff: optional private note, public handoff message,
  # + Conversation#bot_handoff! + out-of-office template when applicable (Captain-aligned).
  class BotHandoffJob < ApplicationJob
    queue_as :default

    def perform(conversation_id, assistant_id, reason = nil, source = 'keyword')
      conversation = Conversation.find_by(id: conversation_id)
      assistant = WlAiAssistant.find_by(id: assistant_id)
      return if conversation.blank? || assistant.blank?

      inbox = conversation.inbox
      return if inbox.respond_to?(:captain_active?) && inbox.captain_active?
      return unless inbox.wl_ai_assistant&.id == assistant.id
      return if conversation.campaign.present?
      return if conversation.tweet?

      conversation.with_lock do
        conversation.reload
        return unless conversation.pending?

        ActiveRecord::Base.transaction do
          previous_executed_by = Current.executed_by
          Current.executed_by = assistant
          begin
            if reason.present?
              conversation.messages.create!(
                message_type: :outgoing,
                private: true,
                sender: assistant,
                account_id: conversation.account_id,
                inbox_id: conversation.inbox_id,
                content: reason.to_s.truncate(15_000),
                additional_attributes: {}
              )
            end

            handoff_body = (assistant.config || {})['handoff_message'].presence ||
                           I18n.t('conversations.wl_ai.handoff', locale: conversation.account.locale)

            conversation.messages.create!(
              message_type: :outgoing,
              private: false,
              sender: assistant,
              account_id: conversation.account_id,
              inbox_id: conversation.inbox_id,
              content: handoff_body,
              additional_attributes: {}
            )

            conversation.bot_handoff!
          ensure
            Current.executed_by = previous_executed_by
          end
        end
      end

      ::MessageTemplates::Template::OutOfOffice.perform_if_applicable(conversation.reload)

      Rails.logger.info(
        "[WlAi::BotHandoffJob] conversation_id=#{conversation_id} assistant_id=#{assistant_id} source=#{source}"
      )
    end
  end
end
