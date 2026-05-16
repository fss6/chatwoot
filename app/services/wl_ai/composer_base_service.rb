# frozen_string_literal: true

module WlAi
  # Shared LLM wiring for agent-assist actions in the reply composer (MIT fork).
  class ComposerBaseService
    GPT_MODEL = Llm::Config::DEFAULT_MODEL
    TOKEN_LIMIT = 400_000

    pattr_initialize [:account!, :conversation_display_id!, { user: nil, content: nil }]

    def call
      return failure(I18n.t('wl_ai.errors.missing_token')) unless credential_present?
      return failure(I18n.t('wl_ai.composer.errors.no_assistant')) if assistant.blank?

      message = generate_message
      return failure(I18n.t('wl_ai.composer.errors.empty_response')) if message.blank?

      success(message)
    rescue ActiveRecord::RecordNotFound
      failure(I18n.t('wl_ai.composer.errors.conversation_not_found'))
    rescue StandardError => e
      Rails.logger.error("[WlAi::#{self.class.name}] #{e.class}: #{e.message}")
      ChatwootExceptionTracker.new(e, account: account).capture_exception
      failure(e.message)
    end

    private

    def generate_message
      raise NotImplementedError
    end

    def conversation
      @conversation ||= account.conversations.find_by!(display_id: conversation_display_id)
    end

    def assistant
      @assistant ||= conversation.inbox.wl_ai_assistant || account.wl_ai_assistants.order(:id).first
    end

    def credential
      @credential ||= account.wl_ai_account_credential
    end

    def credential_present?
      credential.present? && credential.api_token.present?
    end

    def llm_complete(system_prompt, user_content)
      api_base = LlmPingService.normalized_api_base(credential.api_base)
      model_id = credential.effective_model
      reply_text = nil

      Llm::Config.with_api_key(credential.api_token, api_base: api_base) do |context|
        chat = context.chat(model: model_id)
        chat.with_instructions(system_prompt)
        reply = chat.ask(user_content.to_s)
        reply_text = reply.content.to_s.strip
      end

      reply_text
    end

    def prompt_from_file(file_name)
      Rails.root.join('lib/wl_ai/prompts', "#{file_name}.liquid").read
    end

    def render_liquid(template_content, variables = {})
      Liquid::Template.parse(template_content).render(variables.stringify_keys)
    end

    def assistant_context_text
      AssistantPromptBuilder.system_prompt_for(assistant)
    end

    def formatted_conversation
      LlmFormatter::ConversationLlmFormatter.new(conversation).format(token_limit: TOKEN_LIMIT)
    end

    def success(message)
      { message: message }
    end

    def failure(error)
      { error: error }
    end
  end
end
