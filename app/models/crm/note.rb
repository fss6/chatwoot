# == Schema Information
#
# Table name: crm_notes
#
#  id         :bigint           not null, primary key
#  content    :text             not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  account_id :bigint           not null
#  deal_id    :bigint           not null
#  user_id    :bigint
#
# Indexes
#
#  index_crm_notes_on_account_id                             (account_id)
#  index_crm_notes_on_account_id_and_deal_id_and_created_at  (account_id,deal_id,created_at)
#  index_crm_notes_on_deal_id                                (deal_id)
#  index_crm_notes_on_user_id                                (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id)
#  fk_rails_...  (deal_id => crm_deals.id)
#  fk_rails_...  (user_id => users.id)
#
module Crm
  class Note < ApplicationRecord
    self.table_name = 'crm_notes'

    belongs_to :account
    belongs_to :deal, class_name: 'Crm::Deal'
    belongs_to :user, optional: true

    validates :content, presence: true
    validates :account_id, presence: true
    validates :deal_id, presence: true

    scope :latest, -> { order(created_at: :desc) }
  end
end
