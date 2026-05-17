class Api::V1::Accounts::Crm::PipelinesController < Api::V1::Accounts::Crm::BaseController
  before_action :fetch_pipeline, only: [:show, :update, :destroy]
  before_action :check_authorization

  def index
    @pipelines = policy_scope(Crm::Pipeline).active.ordered.includes(:stages)
  end

  def show; end

  def create
    @pipeline = Current.account.crm_pipelines.create!(permitted_params)
  end

  def update
    @pipeline.update!(permitted_params)
  end

  def destroy
    @pipeline.destroy!
    head :ok
  end

  private

  def fetch_pipeline
    @pipeline = policy_scope(Crm::Pipeline).find(params[:id])
  end

  def check_authorization
    authorize(Crm::Pipeline)
    authorize(@pipeline) if @pipeline.present?
  end

  def permitted_params
    params.require(:pipeline).permit(:name, :description, :position, :active)
  end
end
