# frozen_string_literal: true

module WlAi
  class ComposerSummarizeService < ComposerBaseService
    private

    def generate_message
      system_prompt = "#{prompt_from_file('summary')}\n\nReply in #{account.locale_english_name}."
      user_content = conversation.to_llm_text(include_contact_details: false)
      llm_complete(system_prompt, user_content)
    end
  end
end
