module Crm
  class Pipeline < ApplicationRecord
    self.table_name = 'crm_pipelines'

    belongs_to :account
    has_many :stages, class_name: 'Crm::Stage', foreign_key: :pipeline_id, dependent: :destroy
    has_many :deals, class_name: 'Crm::Deal', foreign_key: :pipeline_id, dependent: :restrict_with_error

    validates :name, presence: true
    validates :position, numericality: { only_integer: true }

    scope :active, -> { where(active: true) }
    scope :ordered, -> { order(:position, :id) }
  end
end
