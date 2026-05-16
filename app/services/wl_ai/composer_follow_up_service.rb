# frozen_string_literal: true

module WlAi
  class ComposerFollowUpService < ComposerBaseService
    ALLOWED_EVENT_NAMES = (
      ComposerRewriteService::ALLOWED_OPERATIONS + %w[summarize reply_suggestion]
    ).freeze

    pattr_initialize [:account!, :conversation_display_id!, :follow_up_context!, :user_message!, { user: nil }]

    def call
      return failure(I18n.t('wl_ai.errors.missing_token')) unless credential_present?
      return failure(I18n.t('wl_ai.composer.errors.follow_up_context_missing')) unless valid_follow_up_context?
      return failure(I18n.t('wl_ai.composer.errors.no_assistant')) if assistant.blank?

      message = perform_follow_up
      return failure(I18n.t('wl_ai.composer.errors.empty_response')) if message.blank?

      {
        message: message,
        follow_up_context: update_follow_up_context(user_message, message)
      }
    rescue ActiveRecord::RecordNotFound
      failure(I18n.t('wl_ai.composer.errors.conversation_not_found'))
    rescue StandardError => e
      Rails.logger.error("[WlAi::#{self.class.name}] #{e.class}: #{e.message}")
      ChatwootExceptionTracker.new(e, account: account).capture_exception
      failure(e.message)
    end

    private

    def perform_follow_up
      messages = [
        { role: 'system', content: build_follow_up_system_prompt(follow_up_context) },
        { role: 'user', content: follow_up_context['original_context'] },
        { role: 'assistant', content: follow_up_context['last_response'] },
        *follow_up_history_messages,
        { role: 'user', content: user_message }
      ]
      llm_complete_messages(messages)
    end

    def follow_up_history_messages
      follow_up_context['conversation_history'].to_a.map do |msg|
        { role: msg['role'], content: msg['content'] }
      end
    end

    def build_follow_up_system_prompt(session_data)
      action_context = describe_previous_action(session_data['event_name'])

      <<~PROMPT
        You just performed a #{action_context} action for a customer support agent.
        Your job now is to help them refine the result based on their feedback.
        Be concise and focused on their specific request.
        Output only the reply, no preamble, tags, or explanation.
      PROMPT
    end

    def describe_previous_action(event_name)
      case event_name
      when 'professional', 'casual', 'friendly', 'confident', 'straightforward'
        "tone rewrite (#{event_name})"
      when 'fix_spelling_grammar'
        'spelling and grammar correction'
      when 'improve'
        'message improvement'
      when 'summarize'
        'conversation summary'
      when 'reply_suggestion'
        'reply suggestion'
      else
        event_name
      end
    end

    def valid_follow_up_context?
      return false unless follow_up_context.is_a?(Hash)
      return false unless ALLOWED_EVENT_NAMES.include?(follow_up_context['event_name'])

      %w[event_name original_context last_response].all? { |key| follow_up_context[key].present? }
    end

    def update_follow_up_context(user_msg, assistant_msg)
      updated_history = follow_up_context['conversation_history'].to_a + [
        { 'role' => 'user', 'content' => user_msg },
        { 'role' => 'assistant', 'content' => assistant_msg }
      ]

      {
        'event_name' => follow_up_context['event_name'],
        'original_context' => follow_up_context['original_context'],
        'last_response' => assistant_msg,
        'conversation_history' => updated_history,
        'channel_type' => follow_up_context['channel_type'] || conversation.inbox.channel_type
      }
    end

    def generate_message
      raise NotImplementedError
    end

    def event_name
      'follow_up'
    end

    def follow_up_original_context
      raise NotImplementedError
    end
  end
end
