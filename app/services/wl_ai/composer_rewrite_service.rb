# frozen_string_literal: true

module WlAi
  class ComposerRewriteService < ComposerBaseService
    TONE_OPERATIONS = %w[casual professional friendly confident straightforward].freeze
    ALLOWED_OPERATIONS = (%w[fix_spelling_grammar improve] + TONE_OPERATIONS).freeze

    pattr_initialize [:account!, :conversation_display_id!, :operation!, :content!, { user: nil }]

    def call
      return failure(I18n.t('wl_ai.composer.errors.invalid_operation')) unless ALLOWED_OPERATIONS.include?(operation.to_s)

      super
    end

    private

    def event_name
      operation.to_s
    end

    def follow_up_original_context
      content.to_s
    end

    def generate_message
      case operation.to_s
      when 'fix_spelling_grammar'
        system_prompt = prompt_from_file('fix_spelling_grammar')
        llm_complete(system_prompt, content)
      when 'improve'
        system_prompt = render_liquid(
          prompt_from_file('improve'),
          'conversation_context' => conversation.to_llm_text(include_contact_details: true),
          'draft_message' => content
        )
        llm_complete(system_prompt, content)
      else
        system_prompt = render_liquid(prompt_from_file('tone_rewrite'), 'tone' => operation.to_s)
        llm_complete(system_prompt, content)
      end
    end
  end
end
