# frozen_string_literal: true

module WlAi
  # Treat inbox as bot-active when a WL AI assistant is linked (reopen → pending like other bots).
  module InboxActiveBotExtension
    def active_bot?
      super || (respond_to?(:wl_ai_assistant) && wl_ai_assistant.present?)
    end
  end
end
