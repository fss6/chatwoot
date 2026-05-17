class Api::V1::Accounts::Crm::StagesController < Api::V1::Accounts::Crm::BaseController
  before_action :fetch_pipeline, only: [:index, :create]
  before_action :fetch_stage, only: [:show, :update, :destroy]
  before_action :check_authorization

  def index
    @stages = @pipeline.stages.active.ordered
  end

  def show; end

  def create
    @stage = @pipeline.stages.create!(permitted_params.merge(account: Current.account))
  end

  def update
    @stage.update!(permitted_params)
  end

  def destroy
    @stage.destroy!
    head :ok
  end

  private

  def fetch_pipeline
    @pipeline = policy_scope(Crm::Pipeline).find(params[:pipeline_id])
  end

  def fetch_stage
    @stage = Crm::Stage.where(account_id: Current.account.id).find(params[:id])
  end

  def check_authorization
    authorize(Crm::Stage)
    authorize(@stage) if @stage.present?
  end

  def permitted_params
    params.require(:stage).permit(:name, :position, :stage_type, :color, :active)
  end
end
