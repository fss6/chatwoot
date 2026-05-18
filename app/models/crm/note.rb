module Crm
  class Note < ApplicationRecord
    self.table_name = 'crm_notes'

    belongs_to :account
    belongs_to :deal, class_name: 'Crm::Deal'
    belongs_to :user, optional: true

    validates :content, presence: true
    validates :account_id, presence: true
    validates :deal_id, presence: true

    scope :latest, -> { order(created_at: :desc) }
  end
end
