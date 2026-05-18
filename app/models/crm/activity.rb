# == Schema Information
#
# Table name: crm_activities
#
#  id              :bigint           not null, primary key
#  action          :string           not null
#  metadata        :jsonb            not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  account_id      :bigint           not null
#  actor_id        :bigint
#  contact_id      :bigint
#  conversation_id :bigint
#  deal_id         :bigint
#
# Indexes
#
#  idx_on_account_id_contact_id_created_at_82650f86ab             (account_id,contact_id,created_at)
#  idx_on_account_id_conversation_id_created_at_8f7a87f624        (account_id,conversation_id,created_at)
#  index_crm_activities_on_account_id                             (account_id)
#  index_crm_activities_on_account_id_and_action                  (account_id,action)
#  index_crm_activities_on_account_id_and_deal_id_and_created_at  (account_id,deal_id,created_at)
#  index_crm_activities_on_actor_id                               (actor_id)
#  index_crm_activities_on_contact_id                             (contact_id)
#  index_crm_activities_on_conversation_id                        (conversation_id)
#  index_crm_activities_on_deal_id                                (deal_id)
#  index_crm_activities_on_metadata                               (metadata) USING gin
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id)
#  fk_rails_...  (actor_id => users.id)
#  fk_rails_...  (contact_id => contacts.id)
#  fk_rails_...  (conversation_id => conversations.id)
#  fk_rails_...  (deal_id => crm_deals.id)
#
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
