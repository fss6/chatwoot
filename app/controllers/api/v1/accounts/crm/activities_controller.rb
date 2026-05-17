class Api::V1::Accounts::Crm::ActivitiesController < Api::V1::Accounts::Crm::BaseController
  before_action :fetch_deal

  def index
    authorize @deal, :show?, policy_class: Crm::DealPolicy
    @activities = @deal.activities.order(created_at: :desc).includes(:actor)
  end

  private

  def fetch_deal
    @deal = policy_scope(Crm::Deal).find(params[:deal_id])
  end
end
