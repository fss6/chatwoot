class Api::V1::Accounts::Crm::TasksController < Api::V1::Accounts::Crm::BaseController
  before_action :fetch_task, only: [:show, :update, :destroy, :complete, :cancel]
  before_action :check_authorization

  def index
    @tasks = filtered_tasks.includes(:assigned_user, :contact, :conversation, :deal)
  end

  def show; end

  def create
    @task = Crm::Tasks::CreateService.new(
      account: Current.account,
      params: task_params,
      actor: Current.user
    ).perform
  end

  def update
    @task.update!(task_params)
  end

  def destroy
    @task.destroy!
    head :ok
  end

  def complete
    @task = Crm::Tasks::CompleteService.new(task: @task, actor: Current.user).perform
    render :show
  end

  def cancel
    @task = Crm::Tasks::CancelService.new(task: @task, actor: Current.user).perform
    render :show
  end

  private

  def fetch_task
    @task = policy_scope(Crm::Task).find(params[:id])
  end

  def check_authorization
    authorize(Crm::Task)
    authorize(@task) if @task.present?
  end

  def filtered_tasks
    tasks = policy_scope(Crm::Task).order(due_at: :asc, id: :asc)
    tasks = tasks.where(status: params[:status]) if params[:status].present?
    tasks = tasks.where(task_type: params[:task_type]) if params[:task_type].present?
    tasks = tasks.where(priority: params[:priority]) if params[:priority].present?
    tasks = tasks.where(assigned_user_id: params[:assigned_user_id]) if params[:assigned_user_id].present?
    tasks = tasks.where(deal_id: params[:deal_id]) if params[:deal_id].present?
    tasks = tasks.where(contact_id: params[:contact_id]) if params[:contact_id].present?
    tasks = tasks.where(conversation_id: params[:conversation_id]) if params[:conversation_id].present?
    tasks = tasks.where('due_at >= ?', params[:due_from]) if params[:due_from].present?
    tasks = tasks.where('due_at <= ?', params[:due_to]) if params[:due_to].present?
    tasks = tasks.overdue if ActiveModel::Type::Boolean.new.cast(params[:overdue])
    tasks = tasks.today if ActiveModel::Type::Boolean.new.cast(params[:today])
    tasks = tasks.upcoming if ActiveModel::Type::Boolean.new.cast(params[:upcoming])
    tasks
  end

  def task_params
    params.require(:task).permit(
      :title, :description, :task_type, :status, :priority, :due_at,
      :assigned_user_id, :contact_id, :conversation_id, :deal_id
    )
  end
end
