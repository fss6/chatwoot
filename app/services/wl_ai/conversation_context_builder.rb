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
      parts = []
      cred = @account.wl_ai_account_credential
      instructions = cred&.system_instructions.to_s.strip
      if instructions.present?
        parts << "## #{I18n.t('wl_ai.context_builder.instructions_heading')}\n#{instructions}"
      end

      # FAQs from all assistants, stable order: assistant id, then position.
      faqs = @account.wl_ai_faq_entries
        .joins(:wl_ai_assistant)
        .order('wl_ai_assistants.id ASC, wl_ai_faq_entries.position ASC, wl_ai_faq_entries.id ASC')
      if faqs.any?
        header = I18n.t('wl_ai.context_builder.faq_heading')
        body = faqs.each_with_index.map do |faq, idx|
          "Q#{idx + 1}: #{faq.question}\nA#{idx + 1}: #{faq.answer}"
        end.join("\n\n")
        parts << "## #{header}\n#{body}"
      end

      parts.join("\n\n")
    end
  end
end
