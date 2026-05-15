# frozen_string_literal: true

class WlBotExecutionLog < ApplicationRecord
  belongs_to :wl_bot_session

  enum status: { success: 0, failed: 1, skipped: 2 }
end
