# frozen_string_literal: true

class Api::V1::Accounts::WlAi::ComposerTasksController < Api::V1::Accounts::BaseController
  before_action :fetch_conversation
  before_action :check_authorization

  def reply_suggestion
    render_composer_result(
      WlAi::ComposerReplySuggestionService.new(
        account: Current.account,
        conversation_display_id: conversation_display_id,
        user: Current.user
      ).call
    )
  end

  def summarize
    render_composer_result(
      WlAi::ComposerSummarizeService.new(
        account: Current.account,
        conversation_display_id: conversation_display_id,
        user: Current.user
      ).call
    )
  end

  def rewrite
    render_composer_result(
      WlAi::ComposerRewriteService.new(
        account: Current.account,
        conversation_display_id: conversation_display_id,
        operation: params[:operation],
        content: params[:content],
        user: Current.user
      ).call
    )
  end

  private

  def fetch_conversation
    @conversation = Current.account.conversations.find_by!(display_id: conversation_display_id)
  end

  def conversation_display_id
    params[:conversation_display_id]
  end

  def check_authorization
    authorize(@conversation, :show?)
  end

  def render_composer_result(result)
    if result[:error]
      render json: { error: result[:error] }, status: :unprocessable_entity
    else
      render json: { message: result[:message] }
    end
  end
end
