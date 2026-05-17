class Crm::TaskPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      base = scope.where(account_id: account.id)
      return base if account_user.administrator?

      accessible_deal_ids = Crm::DealPolicy::Scope.new(user_context, account.crm_deals).resolve.select(:id)
      base.where(assigned_user_id: user.id).or(base.where(deal_id: accessible_deal_ids))
    end
  end

  def index?
    account.feature_enabled?('crm_pipeline')
  end

  def show?
    index? && (account_user.administrator? || record.assigned_user_id == user.id || deal_accessible?)
  end

  def create?
    index?
  end

  def update?
    show?
  end

  def destroy?
    account_user.administrator? || record.assigned_user_id == user.id
  end

  def complete?
    account_user.administrator? || record.assigned_user_id == user.id
  end

  def cancel?
    complete?
  end

  private

  def deal_accessible?
    return false if record.deal_id.blank?

    Crm::DealPolicy.new(user_context, record.deal).show?
  end
end
