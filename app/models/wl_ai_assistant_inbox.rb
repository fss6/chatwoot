# frozen_string_literal: true

# == Schema Information
#
# Table name: wl_ai_assistant_inboxes
#
#  id                 :bigint           not null, primary key
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  inbox_id           :bigint           not null
#  wl_ai_assistant_id :bigint           not null
#
# Indexes
#
#  index_wl_ai_assistant_inboxes_on_assistant_and_inbox  (wl_ai_assistant_id,inbox_id) UNIQUE
#  index_wl_ai_assistant_inboxes_on_inbox_id             (inbox_id)
#  index_wl_ai_assistant_inboxes_on_wl_ai_assistant_id   (wl_ai_assistant_id)
#
# Foreign Keys
#
#  fk_rails_...  (inbox_id => inboxes.id)
#  fk_rails_...  (wl_ai_assistant_id => wl_ai_assistants.id)
#
class WlAiAssistantInbox < ApplicationRecord
  belongs_to :wl_ai_assistant
  belongs_to :inbox

  validates :inbox_id, uniqueness: true
end
