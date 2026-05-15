# frozen_string_literal: true

require 'rails_helper'

RSpec.describe WlBotFlows::AgentBotListenerExtension do
  let(:listener) { AgentBotListener.new }

  let(:agent_bot) do
    create(:agent_bot, account: account, outgoing_url: 'https://example.com/hook',
                       bot_config: { 'managed_by' => 'wl_bot_flows', 'wl_bot_flow_id' => 1 })
  end
  let(:account) { create(:account) }
  let(:payload) { { event: 'message_created', account: { id: account.id } } }

  it 'enqueues ProcessEventJob for wl bot flow bots' do
    expect(WlBotFlows::ProcessEventJob).to receive(:perform_later).with(agent_bot.id, payload.deep_stringify_keys)

    listener.send(:process_webhook_bot_event, agent_bot, payload)
  end

  it 'delegates to webhook for other bots' do
    other_bot = create(:agent_bot, account: account, outgoing_url: 'https://example.com/other')
    expect(AgentBots::WebhookJob).to receive(:perform_later)

    listener.send(:process_webhook_bot_event, other_bot, payload)
  end
end
