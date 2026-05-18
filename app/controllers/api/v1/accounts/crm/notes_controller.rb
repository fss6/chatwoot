class Api::V1::Accounts::Crm::NotesController < Api::V1::Accounts::Crm::BaseController
  before_action :fetch_deal
  before_action :fetch_note, only: [:destroy]

  def index
    authorize @deal, :show?, policy_class: Crm::DealPolicy
    @notes = @deal.notes.latest.includes(:user)
  end

  def create
    authorize @deal, :update?, policy_class: Crm::DealPolicy
    @note = Crm::Notes::CreateService.new(
      deal: @deal,
      actor: Current.user,
      content: note_params[:content]
    ).perform
  end

  def destroy
    authorize @deal, :show?, policy_class: Crm::DealPolicy
    unless @note.user_id == Current.user.id || Current.account_user.administrator?
      raise Pundit::NotAuthorizedError
    end

    @note.destroy!
    head :ok
  end

  private

  def fetch_deal
    @deal = policy_scope(Crm::Deal).find(params[:deal_id])
  end

  def fetch_note
    @note = @deal.notes.find(params[:id])
  end

  def note_params
    params.require(:note).permit(:content)
  end
end
