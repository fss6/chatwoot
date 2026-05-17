class Api::V1::Accounts::Crm::DealsController < Api::V1::Accounts::Crm::BaseController
  before_action :fetch_deal, only: [:show, :update, :destroy, :move, :win, :lose, :archive]
  before_action :check_authorization

  def index
    @deals = filtered_deals.includes(:stage, :pipeline, :contact, :conversation, :assigned_user, :tasks)
    ensure_default_pipeline! if @deals.empty? && params[:pipeline_id].blank?
    @deals = filtered_deals.includes(:stage, :pipeline, :contact, :conversation, :assigned_user, :tasks) if @deals.empty?
  end

  def show; end

  def create
    @deal = Crm::Deals::CreateService.new(
      account: Current.account,
      params: deal_params,
      actor: Current.user
    ).perform
  end

  def update
    @deal = Crm::Deals::UpdateService.new(
      deal: @deal,
      params: deal_params.except(:pipeline_id, :stage_id, :contact_id, :conversation_id),
      actor: Current.user
    ).perform
  end

  def destroy
    @deal.destroy!
    head :ok
  end

  def move
    stage = Crm::Stage.where(account_id: Current.account.id, pipeline_id: @deal.pipeline_id).find(params[:stage_id])
    @deal = Crm::Deals::MoveService.new(
      deal: @deal,
      stage: stage,
      position: params[:position].to_i,
      actor: Current.user
    ).perform
    render :show
  end

  def win
    @deal = Crm::Deals::WinService.new(deal: @deal, actor: Current.user).perform
    render :show
  end

  def lose
    @deal = Crm::Deals::LoseService.new(
      deal: @deal,
      actor: Current.user,
      lost_reason: params[:lost_reason]
    ).perform
    render :show
  end

  def archive
    @deal.update!(status: :archived)
    render :show
  end

  private

  def fetch_deal
    @deal = policy_scope(Crm::Deal).find(params[:id])
  end

  def check_authorization
    authorize(Crm::Deal)
    authorize(@deal) if @deal.present?
  end

  def filtered_deals
    deals = policy_scope(Crm::Deal).ordered
    deals = deals.for_pipeline(params[:pipeline_id]) if params[:pipeline_id].present?
    deals = deals.where(stage_id: params[:stage_id]) if params[:stage_id].present?
    deals = deals.where(status: params[:status]) if params[:status].present?
    deals = deals.where(assigned_user_id: params[:assigned_user_id]) if params[:assigned_user_id].present?
    deals = deals.where(contact_id: params[:contact_id]) if params[:contact_id].present?
    deals = deals.where(conversation_id: params[:conversation_id]) if params[:conversation_id].present?
    deals = deals.where(source: params[:source]) if params[:source].present?
    deals = deals.where(lead_temperature: params[:lead_temperature]) if params[:lead_temperature].present?
    deals = deals.where('created_at >= ?', params[:created_from]) if params[:created_from].present?
    deals = deals.where('created_at <= ?', params[:created_to]) if params[:created_to].present?
    deals
  end

  def ensure_default_pipeline!
    Crm::Pipelines::DefaultSetupService.new(account: Current.account).perform
  end

  def deal_params
    params.require(:deal).permit(
      :title, :description, :amount, :currency, :source, :lead_temperature,
      :expected_close_date, :pipeline_id, :stage_id, :contact_id, :conversation_id, :assigned_user_id
    )
  end
end
