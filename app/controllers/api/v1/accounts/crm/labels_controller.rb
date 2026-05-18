class Api::V1::Accounts::Crm::LabelsController < Api::V1::Accounts::Crm::BaseController
  include LabelConcern

  before_action :fetch_deal

  private

  def fetch_deal
    @deal = policy_scope(Crm::Deal).find(params[:deal_id])
    authorize @deal, :update?, policy_class: Crm::DealPolicy
  end

  def model
    @deal
  end

  def permitted_params
    params.permit(labels: [])
  end
end
