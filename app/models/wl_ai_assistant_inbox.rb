# frozen_string_literal: true

# == Schema Information
#
# Table name: wl_ai_assistant_inboxes
#
#  id                 :bigint           not null, primary key
#  wl_ai_assistant_id :bigint           not null
#  inbox_id           :bigint           not null
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#
class WlAiAssistantInbox < ApplicationRecord
  belongs_to :wl_ai_assistant
  belongs_to :inbox

  validates :inbox_id, uniqueness: true
end
