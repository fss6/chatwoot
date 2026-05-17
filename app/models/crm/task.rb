module Crm
  class Task < ApplicationRecord
    self.table_name = 'crm_tasks'

    belongs_to :account
    belongs_to :assigned_user, class_name: 'User', optional: true
    belongs_to :contact, optional: true
    belongs_to :conversation, optional: true
    belongs_to :deal, class_name: 'Crm::Deal', optional: true

    enum task_type: {
      follow_up: 0, call: 1, send_proposal: 2, send_contract: 3,
      payment_check: 4, meeting: 5, other: 6
    }
    enum status: { pending: 0, done: 1, cancelled: 2 }
    enum priority: { low: 0, normal: 1, high: 2, urgent: 3 }

    validates :title, presence: true
    validate :must_have_context

    scope :pending, -> { where(status: :pending) }
    scope :overdue, -> { pending.where('due_at < ?', Time.current) }
    scope :today, -> { pending.where(due_at: Time.zone.today.all_day) }
    scope :upcoming, -> { pending.where('due_at > ?', Time.zone.today.end_of_day) }

    def overdue?
      pending? && due_at.present? && due_at < Time.current
    end

    private

    def must_have_context
      return if deal_id.present? || contact_id.present? || conversation_id.present?

      errors.add(:base, 'Task must be linked to a deal, contact, or conversation')
    end
  end
end
