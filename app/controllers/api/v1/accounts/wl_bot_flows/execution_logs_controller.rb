# frozen_string_literal: true

class Api::V1::Accounts::WlBotFlows::ExecutionLogsController < Api::V1::Accounts::BaseController
  before_action :authorize_wl_bot_flows_admin!
  before_action :fetch_flow

  def index
    logs = WlBotExecutionLog
           .joins(:wl_bot_session)
           .where(wl_bot_sessions: { wl_bot_flow_id: @flow.id })
           .order(created_at: :desc)
           .limit(per_page)
           .offset((page - 1) * per_page)

    logs = logs.where(wl_bot_sessions: { chatwoot_conversation_id: params[:conversation_id] }) if params[:conversation_id].present?
    logs = logs.where(status: params[:status]) if params[:status].present?

    @execution_logs = logs
    @total_count = WlBotExecutionLog.joins(:wl_bot_session).where(wl_bot_sessions: { wl_bot_flow_id: @flow.id }).count
  end

  private

  def authorize_wl_bot_flows_admin!
    authorize(Current.account, :update?)
  end

  def fetch_flow
    @flow = Current.account.wl_bot_flows.find(params[:flow_id])
  end

  def page
    [params[:page].to_i, 1].max
  end

  def per_page
    val = params[:per_page].to_i
    val = 50 if val <= 0
    [val, 100].min
  end
end
