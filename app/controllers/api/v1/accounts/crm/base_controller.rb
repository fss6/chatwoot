class Api::V1::Accounts::Crm::BaseController < Api::V1::Accounts::BaseController
  before_action :ensure_crm_pipeline_enabled!

  private

  def ensure_crm_pipeline_enabled!
    return if Current.account.feature_enabled?('crm_pipeline')

    render json: { error: 'CRM Pipeline is not enabled for this account' }, status: :forbidden
  end

  def pundit_user
    {
      user: Current.user,
      account: Current.account,
      account_user: Current.account_user
    }
  end
end
