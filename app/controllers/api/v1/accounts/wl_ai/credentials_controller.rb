# frozen_string_literal: true

class Api::V1::Accounts::WlAi::CredentialsController < Api::V1::Accounts::BaseController
  before_action :authorize_credential_access!
  before_action :set_available_models, only: [:show, :update]

  def show
    @credential = @current_account.wl_ai_account_credential
  end

  def update
    @credential = @current_account.wl_ai_account_credential ||
                  @current_account.build_wl_ai_account_credential
    @credential.assign_attributes(credential_update_attributes)
    @credential.save!
    render :show
  rescue ActiveRecord::RecordInvalid => e
    render json: { error: e.record.errors.full_messages.join(', ') }, status: :unprocessable_entity
  end

  def ping
    result = WlAi::LlmPingService.new(credential: @current_account.wl_ai_account_credential).perform
    if result[:error]
      render json: { error: result[:error] }, status: :unprocessable_entity
    else
      render json: { ok: true, message: result[:message] }, status: :ok
    end
  end

  private

  def authorize_credential_access!
    authorize(@current_account, :update?)
  end

  def set_available_models
    @available_models = WlAi::AvailableChatModels.as_json_options
  end

  def credential_params
    if params[:wl_ai_account_credential].present?
      params.require(:wl_ai_account_credential).permit(:api_token, :api_base, :default_model, :system_instructions)
    else
      params.permit(:api_token, :api_base, :default_model, :system_instructions)
    end
  end

  def credential_update_attributes
    permitted = credential_params
    attrs = { api_base: permitted[:api_base] }
    attrs[:api_token] = permitted[:api_token] if permitted[:api_token].present?
    if permitted.key?(:default_model) || permitted.key?('default_model')
      attrs[:default_model] = permitted[:default_model].presence
    end
    if permitted.key?(:system_instructions) || permitted.key?('system_instructions')
      attrs[:system_instructions] = permitted[:system_instructions]
    end
    attrs
  end
end
