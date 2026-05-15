# frozen_string_literal: true

module WlAi
  # Detects when the contact asks to speak to a human, using configurable keywords
  # (assistant.config['transfer_keywords']) plus optional i18n defaults.
  class HumanTransferIntentDetector
    MATCH_MODES = %w[substring whole_word].freeze

    class << self
      def match?(message, assistant)
        return false unless message&.incoming?
        return false if message.private?

        text = normalize_text(message.content)
        return false if text.blank?

        keywords = keywords_for(assistant)
        return false if keywords.empty?

        mode = match_mode_for(assistant)
        keywords.any? { |kw| keyword_matches?(text, normalize_text(kw), mode) }
      end

      def keywords_for(assistant)
        cfg = assistant.config || {}
        raw = cfg['transfer_keywords'] || cfg[:transfer_keywords]
        list = Array(raw).map(&:to_s).map(&:strip).reject(&:blank?)
        return default_transfer_keywords if list.empty?

        list
      end

      private

      def default_transfer_keywords
        defs = I18n.t('wl_ai.transfer_intent.default_keywords', default: [])
        defs = defs.is_a?(Array) ? defs : []
        defs.map(&:to_s)
      end

      def match_mode_for(assistant)
        mode = ((assistant.config || {})['transfer_match_mode'] || 'substring').to_s
        MATCH_MODES.include?(mode) ? mode : 'substring'
      end

      def normalize_text(str)
        str.to_s.downcase.squish
      end

      def keyword_matches?(normalized_message, normalized_keyword, mode)
        return false if normalized_keyword.blank?

        if mode == 'whole_word'
          tokens = normalized_message.split(/\W+/).reject(&:blank?)
          tokens.include?(normalized_keyword)
        else
          normalized_message.include?(normalized_keyword)
        end
      end
    end
  end
end
