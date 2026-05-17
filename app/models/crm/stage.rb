module Crm
  class Stage < ApplicationRecord
    self.table_name = 'crm_stages'

    belongs_to :account
    belongs_to :pipeline, class_name: 'Crm::Pipeline'
    has_many :deals, class_name: 'Crm::Deal', foreign_key: :stage_id, dependent: :restrict_with_error

    enum stage_type: { open: 0, won: 1, lost: 2 }

    validates :name, presence: true
    validates :position, presence: true, numericality: { only_integer: true }

    scope :active, -> { where(active: true) }
    scope :ordered, -> { order(:position, :id) }
  end
end
