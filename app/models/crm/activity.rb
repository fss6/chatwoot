module Crm
  class Activity < ApplicationRecord
    self.table_name = 'crm_activities'

    belongs_to :account
    belongs_to :deal, class_name: 'Crm::Deal', optional: true
    belongs_to :contact, optional: true
    belongs_to :conversation, optional: true
    belongs_to :actor, class_name: 'User', optional: true

    validates :action, presence: true
  end
end
