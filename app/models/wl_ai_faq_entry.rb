# frozen_string_literal: true

# == Schema Information
#
# Table name: wl_ai_faq_entries
#
#  id                 :bigint           not null, primary key
#  answer             :text             not null
#  position           :integer          default(0), not null
#  question           :string           not null
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  account_id         :integer          not null
#  wl_ai_assistant_id :bigint           not null
#
# Indexes
#
#  index_wl_ai_faq_entries_on_account_id          (account_id)
#  index_wl_ai_faq_entries_on_wl_ai_assistant_id  (wl_ai_assistant_id)
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id)
#  fk_rails_...  (wl_ai_assistant_id => wl_ai_assistants.id)
#

class WlAiFaqEntry < ApplicationRecord
  belongs_to :account
  belongs_to :wl_ai_assistant

  validates :question, presence: true, length: { maximum: 2_000 }
  validates :answer, presence: true, length: { maximum: 100_000 }
  validates :position, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validate :assistant_belongs_to_same_account

  def as_api_json
    {
      id: id,
      question: question,
      answer: answer,
      position: position,
      wl_ai_assistant_id: wl_ai_assistant_id,
      created_at: created_at&.iso8601(3),
      updated_at: updated_at&.iso8601(3)
    }
  end

  private

  def assistant_belongs_to_same_account
    return if wl_ai_assistant.blank? || account_id.blank?
    return if wl_ai_assistant.account_id == account_id

    errors.add(:wl_ai_assistant, :invalid)
  end
end
