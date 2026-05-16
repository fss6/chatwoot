# frozen_string_literal: true

module WlAi
  class ComposerReplySuggestionService < ComposerBaseService
    private

    def generate_message
      system_prompt = render_liquid(
        prompt_from_file('reply'),
        'channel_type' => conversation.inbox.channel_type,
        'agent_name' => user&.name.to_s,
        'agent_signature' => user&.message_signature.presence,
        'assistant_context' => assistant_context_text
      )

      llm_complete(system_prompt, formatted_conversation)
    end
  end
end
