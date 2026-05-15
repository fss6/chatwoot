# frozen_string_literal: true

require 'rails_helper'

RSpec.describe WlBotFlows::Runtime do
  let(:account) { create(:account) }
  let(:inbox) { create(:inbox, account: account) }
  let(:contact) { create(:contact, account: account) }
  let(:contact_inbox) { create(:contact_inbox, contact: contact, inbox: inbox) }
  let(:conversation) do
    create(:conversation, account: account, inbox: inbox, contact: contact,
                          contact_inbox: contact_inbox, status: :pending)
  end
  let(:published_json) do
    {
      version: 1,
      entry_group_id: 'group_start',
      settings: { default_wait_timeout: 300 },
      groups: [
        {
          id: 'group_start',
          name: 'Start',
          position: { x: 100, y: 100 },
          actions: [
            { id: 'act_1', type: 'send_message', data: { text: 'Hello' } }
          ]
        }
      ],
      edges: []
    }
  end
  let(:flow) do
    create(:wl_bot_flow, account: account, inbox: inbox, draft_json: published_json).tap do |f|
      f.update!(
        status: :published,
        published_json: published_json,
        published_at: Time.current
      )
    end
  end
  let(:agent_bot) do
    create(:agent_bot, account: account, bot_config: {
             'managed_by' => 'wl_bot_flows',
             'wl_bot_flow_id' => flow.id
           })
  end
  let(:session) do
    WlBotSession.create!(
      wl_bot_flow: flow,
      chatwoot_account_id: account.id,
      chatwoot_conversation_id: conversation.id,
      current_group_id: 'group_start',
      current_action_index: 0,
      status: :active
    )
  end
  let(:context) do
    WlBotFlows::EventContext.new(
      'event' => 'message_created',
      'message_type' => 'incoming',
      'content' => 'hello',
      'account' => { 'id' => account.id },
      'inbox' => { 'id' => inbox.id },
      'conversation' => { 'id' => conversation.id }
    )
  end

  def run_runtime
    described_class.new(
      bot_flow: flow,
      session: session,
      context: context,
      agent_bot: agent_bot
    ).call
    session.reload
  end

  before do
    flow.update!(agent_bot: agent_bot)
    create(:agent_bot_inbox, inbox: inbox, agent_bot: agent_bot, account: account)
  end

  it 'sends a message for send_message action' do
    expect { run_runtime }.to change { conversation.messages.outgoing.count }.by(1)
  end

  it 'finishes the session when the group has no next_group_id' do
    run_runtime
    expect(session).to be_finished
  end

  it 'moves to the next group when next_group_id is set' do
    published_json[:groups][0]['next_group_id'] = 'group_b'
    published_json[:groups] << {
      id: 'group_b',
      name: 'Second',
      position: { x: 200, y: 100 },
      actions: [
        { id: 'act_2', type: 'send_message', data: { text: 'From B' } }
      ]
    }
    flow.update!(published_json: published_json)

    expect { run_runtime }.to change { conversation.messages.outgoing.count }.by(2)
    expect(session).to be_finished
    expect(session.current_group_id).to eq('group_b')
    expect(session.current_action_index).to eq(1)
  end

  it 'follows next_group_id immediately for an empty group' do
    published_json[:groups] = [
      {
        id: 'group_empty',
        name: 'Empty',
        position: { x: 0, y: 0 },
        actions: [],
        next_group_id: 'group_b'
      },
      {
        id: 'group_b',
        name: 'Target',
        position: { x: 200, y: 0 },
        actions: [
          { id: 'act_2', type: 'send_message', data: { text: 'Reached B' } }
        ]
      }
    ]
    published_json[:entry_group_id] = 'group_empty'
    flow.update!(published_json: published_json)
    session.update!(current_group_id: 'group_empty', current_action_index: 0)

    expect { run_runtime }.to change { conversation.messages.outgoing.count }.by(1)
    expect(session.current_group_id).to eq('group_b')
    expect(session).to be_finished
  end
end
