# frozen_string_literal: true

module WlAi
  # Prepended to Message for WL AI bot semantics and pending→open handoff (OSS-safe).
  module MessageExtension
    def bot_response?
      (outgoing? && sender_type == 'WlAiAssistant') || super
    end

    def valid_first_reply?
      return false unless human_response? && !private?
      return false if conversation.first_reply_created_at.present?
      return false if conversation.messages.outgoing
                                  .where.not(sender_type: %w[AgentBot Captain::Assistant WlAiAssistant])
                                  .where.not(private: true)
                                  .where("(additional_attributes->'campaign_id') is null").count > 1

      true
    end

    def mark_pending_conversation_as_open_for_human_response
      if wl_ai_pending_for_handoff?
        open_wl_ai_pending_for_human!
      end
      super
    end

    private

    def wl_ai_pending_for_handoff?
      return false if wl_ai_template_bootstrap_message?

      conversation.pending? &&
        ::WlAiAssistantInbox.exists?(inbox_id: conversation.inbox_id) &&
        human_response? &&
        !private?
    end

    def wl_ai_template_bootstrap_message?
      additional_attributes['template_params'].present? &&
        !conversation.messages.incoming.exists?
    end

    def open_wl_ai_pending_for_human!
      previous_user = Current.user
      previous_executed_by = Current.executed_by
      Current.user = nil
      Current.executed_by = nil

      begin
        conversation.open!
        return unless conversation.saved_change_to_status?

        ::Conversations::ActivityMessageJob.perform_later(
          conversation,
          account_id: conversation.account_id,
          inbox_id: conversation.inbox_id,
          message_type: :activity,
          content: I18n.t('conversations.activity.wl_ai.auto_opened_after_agent_reply', locale: conversation.account.locale)
        )
      ensure
        Current.user = previous_user
        Current.executed_by = previous_executed_by
      end
    end
  end
end
