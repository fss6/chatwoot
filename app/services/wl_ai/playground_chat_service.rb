# frozen_string_literal: true

module WlAi
  # One-shot chat completion for the WL AI dashboard playground (per assistant).
  class PlaygroundChatService
    MAX_MESSAGES = 24
    MAX_CONTENT_CHARS = 12_000
    ALLOWED_ROLES = %w[user assistant].freeze

    def initialize(account:, assistant:, messages:)
      @account = account
      @assistant = assistant
      @messages = normalize_messages(messages)
    end

    def call
      err = validate_messages
      return failure(err) if err

      credential = @account.wl_ai_account_credential
      return failure(I18n.t('wl_ai.errors.missing_token')) if credential.blank? || credential.api_token.blank?

      api_base = LlmPingService.normalized_api_base(credential.api_base)
      system_prompt = build_system_prompt(credential)

      Llm::Config.with_api_key(credential.api_token, api_base: api_base) do |context|
        chat = context.chat(model: credential.effective_model)
        chat.with_instructions(system_prompt)
        conv = @messages
        conv[0...-1].each do |msg|
          chat.add_message(role: msg[:role].to_sym, content: msg[:content].to_s)
        end
        reply = chat.ask(conv.last[:content].to_s)
        success_payload(reply)
      end
    rescue StandardError => e
      failure(e.message)
    end

    private

    def normalize_messages(raw)
      Array(raw).map do |m|
        h = m.respond_to?(:symbolize_keys) ? m.symbolize_keys : m.to_h.symbolize_keys
        { role: h[:role].to_s, content: h[:content].to_s }
      end
    end

    def validate_messages
      return I18n.t('wl_ai.playground.errors.messages_required') if @messages.blank?

      return I18n.t('wl_ai.playground.errors.too_many_messages') if @messages.length > MAX_MESSAGES

      @messages.each_with_index do |msg, idx|
        return I18n.t('wl_ai.playground.errors.invalid_role') unless ALLOWED_ROLES.include?(msg[:role])

        if msg[:content].blank? || msg[:content].length > MAX_CONTENT_CHARS
          return I18n.t('wl_ai.playground.errors.invalid_content', index: idx + 1)
        end
      end

      return I18n.t('wl_ai.playground.errors.must_start_with_user') unless @messages.first[:role] == 'user'

      return I18n.t('wl_ai.playground.errors.must_end_with_user') unless @messages.last[:role] == 'user'

      @messages.each_cons(2) do |a, b|
        return I18n.t('wl_ai.playground.errors.alternation') if a[:role] == b[:role]
      end

      nil
    end

    def build_system_prompt(credential)
      parts = []
      parts << "## #{I18n.t('wl_ai.playground.system.assistant_heading')}\n" \
               "#{I18n.t('wl_ai.playground.system.name_label')}: #{@assistant.name}\n" \
               "#{I18n.t('wl_ai.playground.system.description_label')}: #{@assistant.description}"
      if @assistant.product_name.present?
        parts << "#{I18n.t('wl_ai.playground.system.product_label')}: #{@assistant.product_name}"
      end

      instructions = credential.system_instructions.to_s.strip
      if instructions.present?
        parts << "## #{I18n.t('wl_ai.context_builder.instructions_heading')}\n#{instructions}"
      end

      faqs = @assistant.wl_ai_faq_entries.order(:position, :id)
      if faqs.any?
        header = I18n.t('wl_ai.context_builder.faq_heading')
        body = faqs.each_with_index.map do |faq, idx|
          "Q#{idx + 1}: #{faq.question}\nA#{idx + 1}: #{faq.answer}"
        end.join("\n\n")
        parts << "## #{header}\n#{body}"
      end

      parts.join("\n\n")
    end

    def success_payload(reply)
      {
        message: reply.content.to_s,
        usage: {
          prompt_tokens: reply.input_tokens,
          completion_tokens: reply.output_tokens,
          total_tokens: ((reply.input_tokens || 0) + (reply.output_tokens || 0))
        }
      }
    end

    def failure(message)
      { error: message }
    end
  end
end
