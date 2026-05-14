# frozen_string_literal: true

module WlAi
  module AvailableChatModels
    EXCLUDED_IDS = %w[whisper-1 text-embedding-3-small].freeze

    class << self
      def as_json_options
        openai_chat_models.sort_by { |id, _| id.to_s }.map do |id, meta|
          {
            id: id.to_s,
            display_name: meta['display_name'].presence || id.to_s,
            provider: meta['provider'].to_s
          }
        end
      end

      def allowed_ids
        openai_chat_models.keys.map(&:to_s)
      end

      def openai_chat_models
        Llm::Models.models.select do |id, meta|
          next false if EXCLUDED_IDS.include?(id.to_s)

          meta['provider'].to_s == 'openai' && !meta['coming_soon']
        end
      end
    end
  end
end
