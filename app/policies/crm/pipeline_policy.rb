class Crm::PipelinePolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      scope.where(account_id: account.id)
    end
  end

  def index?
    account.feature_enabled?('crm_pipeline')
  end

  def show?
    index?
  end

  def create?
    account_user.administrator? && index?
  end

  def update?
    create?
  end

  def destroy?
    create?
  end
end
