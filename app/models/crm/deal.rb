# == Schema Information
#
# Table name: crm_deals
#
#  id                  :bigint           not null, primary key
#  amount              :decimal(12, 2)
#  closed_at           :datetime
#  currency            :string           default("BRL"), not null
#  description         :text
#  expected_close_date :date
#  lead_temperature    :integer          default("warm"), not null
#  lost_reason         :text
#  position            :integer          default(0), not null
#  source              :string
#  status              :integer          default("open"), not null
#  title               :string           not null
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  account_id          :bigint           not null
#  assigned_user_id    :bigint
#  contact_id          :bigint           not null
#  conversation_id     :bigint
#  pipeline_id         :bigint           not null
#  stage_id            :bigint           not null
#
# Indexes
#
#  index_crm_deals_on_account_id                            (account_id)
#  index_crm_deals_on_account_id_and_assigned_user_id       (account_id,assigned_user_id)
#  index_crm_deals_on_account_id_and_contact_id             (account_id,contact_id)
#  index_crm_deals_on_account_id_and_conversation_id        (account_id,conversation_id)
#  index_crm_deals_on_account_id_and_expected_close_date    (account_id,expected_close_date)
#  index_crm_deals_on_account_id_and_pipeline_id            (account_id,pipeline_id)
#  index_crm_deals_on_account_id_and_stage_id_and_position  (account_id,stage_id,position)
#  index_crm_deals_on_account_id_and_status                 (account_id,status)
#  index_crm_deals_on_assigned_user_id                      (assigned_user_id)
#  index_crm_deals_on_contact_id                            (contact_id)
#  index_crm_deals_on_conversation_id                       (conversation_id)
#  index_crm_deals_on_pipeline_id                           (pipeline_id)
#  index_crm_deals_on_stage_id                              (stage_id)
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id)
#  fk_rails_...  (assigned_user_id => users.id)
#  fk_rails_...  (contact_id => contacts.id)
#  fk_rails_...  (conversation_id => conversations.id)
#  fk_rails_...  (pipeline_id => crm_pipelines.id)
#  fk_rails_...  (stage_id => crm_stages.id)
#
module Crm
  class Deal < ApplicationRecord
    include Labelable

    self.table_name = 'crm_deals'

    belongs_to :account
    belongs_to :pipeline, class_name: 'Crm::Pipeline'
    belongs_to :stage, class_name: 'Crm::Stage'
    belongs_to :contact
    belongs_to :conversation, optional: true
    belongs_to :assigned_user, class_name: 'User', optional: true

    has_many :tasks, class_name: 'Crm::Task', foreign_key: :deal_id, dependent: :nullify
    has_many :activities, class_name: 'Crm::Activity', foreign_key: :deal_id, dependent: :destroy
    has_many :notes, class_name: 'Crm::Note', foreign_key: :deal_id, dependent: :destroy

    enum status: { open: 0, won: 1, lost: 2, archived: 3 }
    enum lead_temperature: { cold: 0, warm: 1, hot: 2 }

    validates :title, presence: true
    validates :amount, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
    validates :lost_reason, length: { maximum: 10_000 }, allow_nil: true

    scope :ordered, -> { order(:position, :id) }
    scope :for_pipeline, ->(pipeline_id) { where(pipeline_id: pipeline_id) }

    def next_pending_task
      tasks.pending.where('due_at IS NULL OR due_at >= ?', Time.current).order(:due_at).first
    end

    def no_next_step?
      open? && tasks.pending.where('due_at IS NULL OR due_at >= ?', Time.current).none?
    end

    def reconcile_status_with_stage!
      return unless stage

      if stage.open? && (won? || lost?)
        update!(status: :open, closed_at: nil, lost_reason: nil)
      elsif stage.won? && !won?
        update!(status: :won, closed_at: closed_at || Time.current, lost_reason: nil)
      elsif stage.lost? && !lost? && lost_reason.present?
        update!(status: :lost, closed_at: closed_at || Time.current)
      end
    end
  end
end
