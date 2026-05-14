# frozen_string_literal: true

class Api::V1::Accounts::WlAi::PlaygroundMessagesController < Api::V1::Accounts::BaseController
  before_action :authorize_wl_ai_admin!
  before_action :fetch_wl_ai_assistant

  def create
    messages = params.require(:playground).permit(messages: %i[role content])[:messages] || []
    result = WlAi::PlaygroundChatService.new(
      account: Current.account,
      assistant: @wl_ai_assistant,
      messages: messages
    ).call

    if result[:error]
      render json: { error: result[:error] }, status: :unprocessable_entity
    else
      render json: result
    end
  rescue ActionController::ParameterMissing
    return render json: { error: I18n.t('wl_ai.playground.errors.parameter_missing') }, status: :bad_request
  end

  private

  def authorize_wl_ai_admin!
    authorize(Current.account, :update?)
  end

  def fetch_wl_ai_assistant
    @wl_ai_assistant = Current.account.wl_ai_assistants.find(params[:assistant_id])
  end
end
