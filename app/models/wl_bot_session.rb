# frozen_string_literal: true

class WlBotSession < ApplicationRecord
  belongs_to :wl_bot_flow
  has_many :wl_bot_execution_logs, dependent: :destroy_async

  enum status: {
    active: 0,
    waiting_contact_message: 1,
    transferred_to_human: 2,
    finished: 3,
    paused: 4,
    failed: 5
  }

  def conversation
    @conversation ||= Conversation.find_by(
      id: chatwoot_conversation_id,
      account_id: chatwoot_account_id
    )
  end
end
