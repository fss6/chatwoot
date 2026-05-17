class Crm::DealPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      base = scope.where(account_id: account.id)
      return base if account_user.administrator?

      accessible_conversation_ids = ConversationPolicy::Scope.new(user_context, account.conversations).resolve.select(:id)
      base.where(assigned_user_id: user.id).or(base.where(conversation_id: accessible_conversation_ids))
    end
  end

  def index?
    account.feature_enabled?('crm_pipeline')
  end

  def show?
    index? && (account_user.administrator? || assigned? || conversation_accessible?)
  end

  def create?
    index?
  end

  def update?
    show?
  end

  def destroy?
    account_user.administrator?
  end

  def move?
    update?
  end

  def win?
    update?
  end

  def lose?
    update?
  end

  def archive?
    update?
  end

  private

  def assigned?
    record.assigned_user_id == user.id
  end

  def conversation_accessible?
    return false if record.conversation_id.blank?

    ConversationPolicy.new(user_context, record.conversation).show?
  end
end
