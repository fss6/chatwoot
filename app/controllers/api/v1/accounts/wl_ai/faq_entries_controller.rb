# frozen_string_literal: true

# Nested under assistants in routes; constant is Api::V1::Accounts::WlAi::FaqEntriesController
# (Rails does not use WlAi::Assistants::FaqEntriesController for this nesting + scope).
class Api::V1::Accounts::WlAi::FaqEntriesController < Api::V1::Accounts::BaseController
  before_action :authorize_wl_ai_admin!
  before_action :fetch_wl_ai_assistant
  before_action :fetch_faq_entry, only: [:update, :destroy]

  def index
    entries = @wl_ai_assistant.wl_ai_faq_entries.order(:position, :id)
    render json: entries.map(&:as_api_json)
  end

  def create
    entry = @wl_ai_assistant.wl_ai_faq_entries.new(faq_entry_params)
    entry.account_id = Current.account.id
    entry.save!
    render json: entry.as_api_json, status: :created
  rescue ActiveRecord::RecordInvalid => e
    render json: { error: e.record.errors.full_messages.join(', ') }, status: :unprocessable_entity
  end

  def update
    @faq_entry.update!(faq_entry_params)
    render json: @faq_entry.as_api_json
  rescue ActiveRecord::RecordInvalid => e
    render json: { error: e.record.errors.full_messages.join(', ') }, status: :unprocessable_entity
  end

  def destroy
    @faq_entry.destroy!
    head :ok
  end

  private

  def authorize_wl_ai_admin!
    authorize(Current.account, :update?)
  end

  def fetch_wl_ai_assistant
    @wl_ai_assistant = Current.account.wl_ai_assistants.find(params[:assistant_id])
  end

  def fetch_faq_entry
    @faq_entry = @wl_ai_assistant.wl_ai_faq_entries.find(params[:id])
  end

  def faq_entry_params
    params.require(:faq_entry).permit(:question, :answer, :position)
  end
end
