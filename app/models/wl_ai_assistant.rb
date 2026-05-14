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
#  config       :jsonb            not null
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#
class WlAiAssistant < ApplicationRecord
  belongs_to :account
  has_many :wl_ai_faq_entries, dependent: :destroy_async

  validates :name, presence: true, length: { maximum: 255 }
  validates :description, presence: true, length: { maximum: 10_000 }
  validates :product_name, length: { maximum: 255 }, allow_blank: true

  scope :ordered, -> { order(created_at: :desc) }

  def as_api_json
    {
      id: id,
      name: name,
      description: description,
      product_name: product_name,
      config: config || {},
      created_at: created_at&.iso8601(3),
      updated_at: updated_at&.iso8601(3)
    }
  end
end
