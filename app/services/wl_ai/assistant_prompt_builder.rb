# frozen_string_literal: true

module WlAi
  # Shared system prompt for playground and inbox auto-reply.
  class AssistantPromptBuilder
    def self.system_prompt_for(assistant)
      new(assistant).system_prompt
    end

    def initialize(assistant)
      @assistant = assistant
    end

    def system_prompt
      parts = []
      parts << "## #{I18n.t('wl_ai.playground.system.assistant_heading')}\n" \
               "#{I18n.t('wl_ai.playground.system.name_label')}: #{@assistant.name}\n" \
               "#{I18n.t('wl_ai.playground.system.description_label')}: #{@assistant.description}"
      if @assistant.product_name.present?
        parts << "#{I18n.t('wl_ai.playground.system.product_label')}: #{@assistant.product_name}"
      end

      instructions = @assistant.instructions.to_s.strip
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

      parts << I18n.t('wl_ai.playground.system.json_handoff_block') if json_handoff_enabled?

      parts.join("\n\n")
    end

    private

    def json_handoff_enabled?
      (@assistant.config || {})['llm_handoff_enabled'].to_s == 'true'
    end
  end
end
