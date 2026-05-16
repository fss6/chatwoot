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

      success(message, follow_up_original_context)
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
      llm_complete_messages(
        [
          { role: 'system', content: system_prompt },
          { role: 'user', content: user_content.to_s }
        ]
      )
    end

    def llm_complete_messages(messages)
      api_base = LlmPingService.normalized_api_base(credential.api_base)
      model_id = credential.effective_model
      reply_text = nil

      Llm::Config.with_api_key(credential.api_token, api_base: api_base) do |context|
        chat = context.chat(model: model_id)
        system_msg = messages.find { |m| m[:role] == 'system' }
        chat.with_instructions(system_msg[:content]) if system_msg

        conversation_messages = messages.reject { |m| m[:role] == 'system' }
        next if conversation_messages.empty?

        if conversation_messages.length > 1
          conversation_messages[0...-1].each do |msg|
            chat.add_message(role: msg[:role].to_sym, content: msg[:content])
          end
        end
        reply = chat.ask(conversation_messages.last[:content])
        reply_text = reply.content.to_s.strip
      end

      reply_text
    end

    def event_name
      raise NotImplementedError
    end

    def follow_up_original_context
      raise NotImplementedError
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

    def success(message, original_context)
      result = { message: message }
      if original_context.present?
        result[:follow_up_context] = build_follow_up_context(original_context, message)
      end
      result
    end

    def build_follow_up_context(original_context, response_message)
      {
        'event_name' => event_name.to_s,
        'original_context' => original_context,
        'last_response' => response_message,
        'conversation_history' => [],
        'channel_type' => conversation.inbox.channel_type
      }
    end

    def failure(error)
      { error: error }
    end
  end
end
