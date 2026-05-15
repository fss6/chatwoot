# frozen_string_literal: true

class Api::V1::Accounts::WlBotFlows::FlowsController < Api::V1::Accounts::BaseController
  before_action :authorize_wl_bot_flows_admin!
  before_action :fetch_flow, only: [:show, :update, :destroy, :publish, :pause, :duplicate]

  def index
    @flows = Current.account.wl_bot_flows.ordered.includes(:inbox, :agent_bot)
  end

  def show; end

  def create
    @flow = Current.account.wl_bot_flows.create!(
      flow_params.merge(
        created_by_id: Current.user.id,
        draft_json: flow_params[:draft_json].presence || default_draft_json
      )
    )
    render :show, status: :created
  end

  def update
    @flow.update!(flow_params.merge(updated_by_id: Current.user.id))
    render :show
  end

  def destroy
    @flow.update!(status: :archived)
    head :ok
  end

  def publish
    @flow.publish!
    render :show
  rescue WlBotFlows::PublishError, WlBotFlows::Validator::ValidationError => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  def pause
    @flow.paused!
    render :show
  end

  def duplicate
    duplicated = Current.account.wl_bot_flows.create!(
      name: "#{@flow.name} - copy",
      inbox_id: @flow.inbox_id,
      draft_json: @flow.draft_json,
      created_by_id: Current.user.id
    )
    render json: { id: duplicated.id }, status: :created
  end

  private

  def authorize_wl_bot_flows_admin!
    authorize(Current.account, :update?)
  end

  def fetch_flow
    @flow = Current.account.wl_bot_flows.find(params[:id])
  end

  def flow_params
    params.require(:flow).permit(:name, :inbox_id, :status, draft_json: {}, published_json: {})
  end

  def default_draft_json
    {
      version: 1,
      entry_group_id: 'group_start',
      settings: { default_wait_timeout: 300, default_tolerance: 2 },
      groups: [
        {
          id: 'group_start',
          name: 'Start',
          position: { x: 260, y: 120 },
          actions: []
        }
      ],
      edges: []
    }
  end
end
