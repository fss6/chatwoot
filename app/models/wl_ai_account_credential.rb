# == Schema Information
#
# Table name: wl_ai_account_credentials
#
#  id         :bigint           not null, primary key
#  account_id :bigint           not null
#  api_base      :string
#  api_token     :string
#  default_model         :string
#  system_instructions   :text
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#
# Indexes
#
#  index_wl_ai_account_credentials_on_account_id  (account_id) UNIQUE
#

class WlAiAccountCredential < ApplicationRecord
  belongs_to :account

  encrypts :api_token if Chatwoot.encryption_configured?

  validates :account_id, uniqueness: true
  validates :api_token, presence: true, on: :create
  validate :default_model_must_be_allowed, if: -> { default_model.present? }

  def effective_model
    default_model.presence || Llm::Config::DEFAULT_MODEL
  end

  private

  def default_model_must_be_allowed
    return if WlAi::AvailableChatModels.allowed_ids.include?(default_model.to_s)

    errors.add(:default_model, I18n.t('wl_ai.errors.invalid_model'))
  end
end
