# frozen_string_literal: true

# == Schema Information
#
# Table name: wl_ai_assistants
#
#  id           :bigint           not null, primary key
#  account_id   :integer          not null
#  name         :string           not null
#  description  :text             not null
#  product_name :string
#  instructions :text
#  config       :jsonb            not null
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#
class WlAiAssistant < ApplicationRecord
  belongs_to :account
  has_many :wl_ai_faq_entries, dependent: :destroy_async
  has_many :wl_ai_assistant_inboxes, dependent: :destroy_async
  has_many :inboxes, through: :wl_ai_assistant_inboxes

  validates :name, presence: true, length: { maximum: 255 }
  validates :description, presence: true, length: { maximum: 10_000 }
  validates :instructions, length: { maximum: 100_000 }, allow_blank: true
  validates :product_name, length: { maximum: 255 }, allow_blank: true

  scope :ordered, -> { order(created_at: :desc) }

  # Used by ConversationReplyMailer and other paths that treat senders like users/bots.
  def available_name
    name
  end

  def as_api_json
    {
      id: id,
      name: name,
      description: description,
      product_name: product_name,
      instructions: instructions,
      config: config || {},
      created_at: created_at&.iso8601(3),
      updated_at: updated_at&.iso8601(3)
    }
  end

  def push_event_data
    {
      id: id,
      name: name,
      description: description,
      created_at: created_at,
      type: 'wl_ai_assistant'
    }
  end

  def webhook_data
    {
      id: id,
      name: name,
      description: description,
      created_at: created_at,
      type: 'wl_ai_assistant'
    }
  end
end
