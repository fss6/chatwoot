module Crm
  class Deal < ApplicationRecord
    self.table_name = 'crm_deals'

    belongs_to :account
    belongs_to :pipeline, class_name: 'Crm::Pipeline'
    belongs_to :stage, class_name: 'Crm::Stage'
    belongs_to :contact
    belongs_to :conversation, optional: true
    belongs_to :assigned_user, class_name: 'User', optional: true

    has_many :tasks, class_name: 'Crm::Task', foreign_key: :deal_id, dependent: :nullify
    has_many :activities, class_name: 'Crm::Activity', foreign_key: :deal_id, dependent: :destroy

    enum status: { open: 0, won: 1, lost: 2, archived: 3 }
    enum lead_temperature: { cold: 0, warm: 1, hot: 2 }

    validates :title, presence: true
    validates :amount, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true

    scope :ordered, -> { order(:position, :id) }
    scope :for_pipeline, ->(pipeline_id) { where(pipeline_id: pipeline_id) }

    def next_pending_task
      tasks.pending.where('due_at IS NULL OR due_at >= ?', Time.current).order(:due_at).first
    end

    def no_next_step?
      open? && tasks.pending.where('due_at IS NULL OR due_at >= ?', Time.current).none?
    end
  end
end
