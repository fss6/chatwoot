# frozen_string_literal: true

module WlAi
  # Generates a single outgoing reply for a pending conversation using account LLM credentials.
  class ConversationReplyService
    MAX_HISTORY_MESSAGES = 24
    MAX_CONTENT_CHARS = 12_000

    def initialize(conversation:, assistant:)
      @conversation = conversation
      @assistant = assistant
      @account = conversation.account
    end

    def call
      @conversation.with_lock do
        @conversation.reload
        return unless @conversation.pending?
        return if @conversation.campaign.present?
        return unless last_message&.incoming?

        credential = @account.wl_ai_account_credential
        return if credential.blank? || credential.api_token.blank?

        messages_for_llm = build_message_sequence
        return if messages_for_llm.blank?
        return unless messages_for_llm.last[:role] == 'user'

        api_base = LlmPingService.normalized_api_base(credential.api_base)
        system_prompt = AssistantPromptBuilder.system_prompt_for(@assistant)
        model_id = credential.effective_model

        reply_text = nil
        Llm::Config.with_api_key(credential.api_token, api_base: api_base) do |context|
          chat = context.chat(model: model_id)
          chat.with_instructions(system_prompt)
          seq = messages_for_llm
          seq[0...-1].each do |msg|
            chat.add_message(role: msg[:role].to_sym, content: msg[:content].to_s)
          end
          reply = chat.ask(seq.last[:content].to_s)
          reply_text = reply.content.to_s
        end

        return if reply_text.blank?

        raw_reply = reply_text

        if json_handoff_mode?
          parsed = parse_structured_llm_reply(raw_reply)
          if parsed[:handoff]
            schedule_llm_bot_handoff(parsed[:reason])
            return
          end

          reply_text = parsed[:message].presence || raw_reply
        end

        return if reply_text.blank?

        create_outgoing_message(reply_text)
      end
    rescue StandardError => e
      Rails.logger.error("[WlAi::ConversationReplyService] #{e.class}: #{e.message}")
      ChatwootExceptionTracker.new(e, account: @account).capture_exception
    end

    private

    def last_message
      @conversation.messages.reorder('messages.id DESC').first
    end

    def build_message_sequence
      rows = @conversation.messages
                          .where(message_type: %i[incoming outgoing])
                          .where(private: false)
                          .reorder('messages.id ASC')
                          .last(MAX_HISTORY_MESSAGES)

      rows.filter_map do |msg|
        role = msg.incoming? ? 'user' : 'assistant'
        text = extract_plain_text(msg)
        next if text.blank?

        text = text.truncate(MAX_CONTENT_CHARS)
        { role: role, content: text }
      end
    end

    def extract_plain_text(message)
      content = message.content.to_s
      return content if content.blank?

      Rails::HTML5::FullSanitizer.new.sanitize(content).squish
    end

    def create_outgoing_message(text)
      previous_executed_by = Current.executed_by
      Current.executed_by = @assistant
      @conversation.messages.create!(
        message_type: :outgoing,
        account_id: @account.id,
        inbox_id: @conversation.inbox_id,
        sender: @assistant,
        content: text
      )
    ensure
      Current.executed_by = previous_executed_by
    end

    def json_handoff_mode?
      (@assistant.config || {})['llm_handoff_enabled'].to_s == 'true'
    end

    def parse_structured_llm_reply(text)
      data = JSON.parse(text.to_s.strip)
      unless data.is_a?(Hash)
        return { handoff: false, message: text.to_s, reason: nil }
      end

      handoff = ActiveModel::Type::Boolean.new.cast(data['handoff'])
      msg = data['message'].to_s
      reason = data['reason'].to_s.presence
      { handoff: handoff, message: msg, reason: reason }
    rescue JSON::ParserError, TypeError
      { handoff: false, message: text.to_s, reason: nil }
    end

    def schedule_llm_bot_handoff(reason)
      last_user = last_message&.content.to_s
      note = reason.presence || last_user.truncate(2_000)
      WlAi::BotHandoffJob.perform_later(@conversation.id, @assistant.id, note, 'llm')
    end
  end
end
