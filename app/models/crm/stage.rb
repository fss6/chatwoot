# == Schema Information
#
# Table name: crm_stages
#
#  id          :bigint           not null, primary key
#  active      :boolean          default(TRUE), not null
#  color       :string
#  name        :string           not null
#  position    :integer          default(0), not null
#  stage_type  :integer          default("open"), not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  account_id  :bigint           not null
#  pipeline_id :bigint           not null
#
# Indexes
#
#  index_crm_stages_on_account_id                               (account_id)
#  index_crm_stages_on_account_id_and_pipeline_id_and_position  (account_id,pipeline_id,position)
#  index_crm_stages_on_account_id_and_stage_type                (account_id,stage_type)
#  index_crm_stages_on_pipeline_id                              (pipeline_id)
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id)
#  fk_rails_...  (pipeline_id => crm_pipelines.id)
#
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
