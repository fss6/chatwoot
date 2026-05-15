# frozen_string_literal: true

module WlAi
  module MessageTemplates
    # Prepended after OSS + Enterprise hooks: runs `super` first, then schedules WL AI
    # when eligible. Does not modify upstream files.
    module HookExtension
      MAX_ATTACHMENT_WAIT_SECONDS = 4

      def trigger_templates
        super
        schedule_wl_ai_reply_if_eligible
      end

      def should_send_greeting?
        return false if wl_ai_handling_conversation?

        super
      end

      def should_send_out_of_office_message?
        return false if wl_ai_handling_conversation?

        super
      end

      def should_send_email_collect?
        return false if wl_ai_handling_conversation?

        super
      end

      private

      def wl_ai_handling_conversation?
        conversation.pending? &&
          inbox.respond_to?(:wl_ai_assistant) &&
          inbox.wl_ai_assistant.present?
      end

      def schedule_wl_ai_reply_if_eligible
        return unless ENV.fetch('WL_AI_AUTO_REPLY', 'false') == 'true'
        return unless wl_ai_auto_reply_context?
        return if captain_takes_precedence?
        return if other_bot_integrations_active?
        return if conversation.campaign.present?
        return if conversation.tweet?

        assistant = inbox.wl_ai_assistant
        if WlAi::HumanTransferIntentDetector.match?(message, assistant)
          schedule_wl_ai_bot_handoff(assistant)
          return
        end

        return unless wl_ai_llm_credentials_present?

        job_args = [conversation.id, assistant.id]
        if message.attachments.blank?
          WlAi::IncomingReplyJob.perform_later(*job_args)
        else
          WlAi::IncomingReplyJob.set(wait: wl_ai_attachment_wait).perform_later(*job_args)
        end
      end

      def wl_ai_auto_reply_context?
        conversation.pending? &&
          message.incoming? &&
          !message.auto_reply_email? &&
          inbox.respond_to?(:wl_ai_assistant) &&
          inbox.wl_ai_assistant.present?
      end

      def wl_ai_llm_credentials_present?
        cred = conversation.account.wl_ai_account_credential
        cred.present? && cred.api_token.present?
      end

      def should_process_wl_ai_response?
        wl_ai_auto_reply_context? && wl_ai_llm_credentials_present?
      end

      def schedule_wl_ai_bot_handoff(assistant)
        reason = message.content.to_s.truncate(2_000)
        source = 'keyword'
        args = [conversation.id, assistant.id, reason, source]
        if message.attachments.blank?
          WlAi::BotHandoffJob.perform_later(*args)
        else
          WlAi::BotHandoffJob.set(wait: wl_ai_attachment_wait).perform_later(*args)
        end
      end

      def captain_takes_precedence?
        inbox.respond_to?(:captain_active?) && inbox.captain_active?
      end

      def other_bot_integrations_active?
        inbox.agent_bot_inbox&.active? ||
          inbox.hooks.where(app_id: %w[dialogflow], status: 'enabled').exists?
      end

      def wl_ai_attachment_wait
        attachment_count = message.attachments.size
        base_wait = 1.second
        additional_wait = [attachment_count * 1, MAX_ATTACHMENT_WAIT_SECONDS].min.seconds
        base_wait + additional_wait
      end
    end
  end
end
