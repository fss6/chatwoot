# frozen_string_literal: true

module WlAi
  # Builds a single text block for system / developer context when integrating
  # WL AI with conversation features (reply assist, copilot fork, etc.).
  class ConversationContextBuilder
    def self.to_text(account)
      new(account).to_text
    end

    def initialize(account)
      @account = account
    end

    def to_text
      sections = @account.wl_ai_assistants.order(:id).filter_map do |assistant|
        assistant_section(assistant)
      end
      sections.join("\n\n")
    end

    private

    def assistant_section(assistant)
      chunks = []
      title = I18n.t('wl_ai.context_builder.assistant_section', name: assistant.name)
      chunks << "## #{title}"
      chunks << assistant.description.to_s.strip

      inst = assistant.instructions.to_s.strip
      if inst.present?
        chunks << ''
        chunks << "### #{I18n.t('wl_ai.context_builder.instructions_heading')}"
        chunks << inst
      end

      faqs = assistant.wl_ai_faq_entries.order(:position, :id).to_a
      if faqs.any?
        chunks << ''
        chunks << "### #{I18n.t('wl_ai.context_builder.faq_heading')}"
        chunks << faqs.each_with_index.map do |faq, idx|
          "Q#{idx + 1}: #{faq.question}\nA#{idx + 1}: #{faq.answer}"
        end.join("\n\n")
      end

      chunks.join("\n").strip
    end
  end
end
