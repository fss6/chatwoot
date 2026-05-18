# == Schema Information
#
# Table name: crm_tasks
#
#  id               :bigint           not null, primary key
#  cancelled_at     :datetime
#  completed_at     :datetime
#  description      :text
#  due_at           :datetime
#  priority         :integer          default("normal"), not null
#  status           :integer          default("pending"), not null
#  task_type        :integer          default("follow_up"), not null
#  title            :string           not null
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  account_id       :bigint           not null
#  assigned_user_id :bigint
#  contact_id       :bigint
#  conversation_id  :bigint
#  deal_id          :bigint
#
# Indexes
#
#  index_crm_tasks_on_account_id                                  (account_id)
#  index_crm_tasks_on_account_id_and_assigned_user_id_and_status  (account_id,assigned_user_id,status)
#  index_crm_tasks_on_account_id_and_contact_id                   (account_id,contact_id)
#  index_crm_tasks_on_account_id_and_conversation_id              (account_id,conversation_id)
#  index_crm_tasks_on_account_id_and_deal_id                      (account_id,deal_id)
#  index_crm_tasks_on_account_id_and_due_at                       (account_id,due_at)
#  index_crm_tasks_on_account_id_and_task_type                    (account_id,task_type)
#  index_crm_tasks_on_assigned_user_id                            (assigned_user_id)
#  index_crm_tasks_on_contact_id                                  (contact_id)
#  index_crm_tasks_on_conversation_id                             (conversation_id)
#  index_crm_tasks_on_deal_id                                     (deal_id)
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id)
#  fk_rails_...  (assigned_user_id => users.id)
#  fk_rails_...  (contact_id => contacts.id)
#  fk_rails_...  (conversation_id => conversations.id)
#  fk_rails_...  (deal_id => crm_deals.id)
#
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
