# frozen_string_literal: true

module WlAi
  module InboxAssociation
    extend ActiveSupport::Concern

    included do
      has_one :wl_ai_assistant_inbox, dependent: :destroy, class_name: 'WlAiAssistantInbox'
      has_one :wl_ai_assistant, through: :wl_ai_assistant_inbox
    end
  end
end
