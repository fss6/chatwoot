# frozen_string_literal: true

class Api::V1::Accounts::WlAi::AssistantsController < Api::V1::Accounts::BaseController
  before_action :authorize_wl_ai_admin!
  before_action :fetch_assistant, only: [:show, :update, :destroy]

  def index
    assistants = Current.account.wl_ai_assistants.ordered
    render json: assistants.map(&:as_api_json)
  end

  def show
    render json: @assistant.as_api_json
  end

  def create
    assistant = Current.account.wl_ai_assistants.new(assistant_params)
    assistant.save!
    render json: assistant.as_api_json, status: :created
  rescue ActiveRecord::RecordInvalid => e
    render json: { error: e.record.errors.full_messages.join(', ') }, status: :unprocessable_entity
  end

  def update
    attrs = assistant_params.to_h
    if attrs.key?('config')
      attrs['config'] = (@assistant.config || {}).stringify_keys.merge(
        (attrs['config'] || {}).stringify_keys
      )
    end
    @assistant.update!(attrs)
    render json: @assistant.as_api_json
  rescue ActiveRecord::RecordInvalid => e
    render json: { error: e.record.errors.full_messages.join(', ') }, status: :unprocessable_entity
  end

  def destroy
    @assistant.destroy!
    head :ok
  end

  private

  def authorize_wl_ai_admin!
    authorize(Current.account, :update?)
  end

  def fetch_assistant
    @assistant = Current.account.wl_ai_assistants.find(params[:id])
  end

  def assistant_params
    prm = params.require(:assistant)
    permitted = prm.permit(:name, :description, :product_name, :instructions)
    if prm.key?(:config)
      permitted[:config] = wl_ai_assistant_config_from(prm[:config])
    end
    permitted
  end

  def wl_ai_assistant_config_from(raw)
    keys = %w[feature_faq feature_memory feature_citations]
    case raw
    when ActionController::Parameters
      raw.permit(*keys).to_h
    when Hash
      raw.stringify_keys.slice(*keys)
    else
      {}
    end
  end
end
