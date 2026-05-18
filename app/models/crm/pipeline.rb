# == Schema Information
#
# Table name: crm_pipelines
#
#  id          :bigint           not null, primary key
#  active      :boolean          default(TRUE), not null
#  description :text
#  name        :string           not null
#  position    :integer          default(0), not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  account_id  :bigint           not null
#
# Indexes
#
#  index_crm_pipelines_on_account_id               (account_id)
#  index_crm_pipelines_on_account_id_and_active    (account_id,active)
#  index_crm_pipelines_on_account_id_and_position  (account_id,position)
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id)
#
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
