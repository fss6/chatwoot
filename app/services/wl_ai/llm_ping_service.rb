# frozen_string_literal: true

module WlAi
  class LlmPingService
    attr_reader :credential

    def initialize(credential:)
      @credential = credential
    end

    def perform
      return { error: I18n.t('wl_ai.errors.missing_token'), error_code: 422 } if credential.blank? || credential.api_token.blank?

      api_base = self.class.normalized_api_base(credential.api_base)
      Llm::Config.with_api_key(credential.api_token, api_base: api_base) do |context|
        chat = context.chat(model: credential.effective_model)
        response = chat.ask('ping')
        { message: response.content.presence || 'ok' }
      end
    rescue StandardError => e
      { error: e.message, error_code: 422 }
    end

    def self.normalized_api_base(url)
      return nil if url.blank?

      base = url.to_s.strip.chomp('/')
      base.end_with?('/v1') ? base : "#{base}/v1"
    end
  end
end
