# frozen_string_literal: true

class Api::V1::Accounts::WlAi::InboxesController < Api::V1::Accounts::BaseController
  before_action :authorize_wl_ai_admin!
  before_action :set_assistant

  def index
    @inboxes = @assistant.inboxes
    @occupied_inbox_ids = WlAiAssistantInbox.joins(:wl_ai_assistant)
                                            .where(wl_ai_assistants: { account_id: Current.account.id })
                                            .pluck(:inbox_id)
  end

  def create
    inbox = Current.account.inboxes.find(assistant_params[:inbox_id])
    @wl_ai_assistant_inbox = @assistant.wl_ai_assistant_inboxes.build(inbox: inbox)
    if @wl_ai_assistant_inbox.save
      render :create, formats: [:json]
    else
      render json: { error: @wl_ai_assistant_inbox.errors.full_messages.join(', ') },
             status: :unprocessable_entity
    end
  end

  def destroy
    @wl_ai_assistant_inbox = @assistant.wl_ai_assistant_inboxes.find_by!(inbox_id: permitted_params[:inbox_id])
    @wl_ai_assistant_inbox.destroy!
    head :no_content
  end

  private

  def set_assistant
    @assistant = Current.account.wl_ai_assistants.find(permitted_params[:assistant_id])
  end

  def permitted_params
    params.permit(:assistant_id, :account_id, :inbox_id)
  end

  def assistant_params
    params.require(:inbox).permit(:inbox_id)
  end

  def authorize_wl_ai_admin!
    authorize(Current.account, :update?)
  end
end
