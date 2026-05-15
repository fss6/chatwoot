# frozen_string_literal: true

require 'rails_helper'

RSpec.describe WlBotFlows::Actions::Condition do
  let(:account) { create(:account) }
  let(:inbox) { create(:inbox, account: account) }
  let(:contact) { create(:contact, account: account, name: 'Caio') }
  let(:contact_inbox) { create(:contact_inbox, contact: contact, inbox: inbox) }
  let(:conversation) do
    create(:conversation, account: account, inbox: inbox, contact: contact, contact_inbox: contact_inbox)
  end
  let(:flow) { create(:wl_bot_flow, account: account, inbox: inbox) }
  let(:agent_bot) { create(:agent_bot, account: account) }
  let(:session) do
    WlBotSession.create!(
      wl_bot_flow: flow,
      chatwoot_account_id: account.id,
      chatwoot_conversation_id: conversation.id,
      variables: { 'intent' => 'sales' },
      status: :active
    )
  end
  let(:context) do
    WlBotFlows::EventContext.new(
      'event' => 'message_created',
      'account' => { 'id' => account.id },
      'inbox' => { 'id' => inbox.id },
      'conversation' => { 'id' => conversation.id }
    )
  end

  def run_condition(data)
    action = { 'id' => 'act_1', 'type' => 'condition', 'data' => data }
    described_class.new(
      action: action,
      session: session,
      context: context,
      flow: flow.published_json,
      agent_bot: agent_bot
    ).call
  end

  it 'routes to target when session variable matches' do
    result = run_condition(
      'rules' => [
        {
          'id' => 'rule_1',
          'label' => 'Sales',
          'logic' => 'and',
          'conditions' => [
            { 'source' => 'session_variable', 'attribute' => 'intent',
              'operator' => 'equals', 'value' => 'sales' }
          ],
          'target_group_id' => 'group_sales'
        }
      ],
      'fallback_group_id' => 'group_default'
    )

    expect(result.status).to eq(:go_to_group)
    expect(result.target_group_id).to eq('group_sales')
  end

  it 'routes to target when contact name matches' do
    result = run_condition(
      'rules' => [
        {
          'id' => 'rule_1',
          'label' => 'Caio',
          'logic' => 'and',
          'conditions' => [
            { 'source' => 'contact', 'attribute' => 'name',
              'operator' => 'equals', 'value' => 'Caio' }
          ],
          'target_group_id' => 'group_caio'
        }
      ],
      'fallback_group_id' => 'group_default'
    )

    expect(result.target_group_id).to eq('group_caio')
  end

  it 'uses fallback when no rule matches' do
    result = run_condition(
      'rules' => [
        {
          'id' => 'rule_1',
          'label' => 'Other',
          'logic' => 'and',
          'conditions' => [
            { 'source' => 'session_variable', 'attribute' => 'intent',
              'operator' => 'equals', 'value' => 'other' }
          ],
          'target_group_id' => 'group_other'
        }
      ],
      'fallback_group_id' => 'group_default'
    )

    expect(result.target_group_id).to eq('group_default')
  end

  it 'supports legacy flat rule format' do
    result = run_condition(
      'rules' => [
        { 'id' => 'rule_1', 'label' => 'Legacy', 'field' => 'intent',
          'operator' => 'equals', 'value' => 'sales', 'target_group_id' => 'group_sales' }
      ],
      'fallback_group_id' => ''
    )

    expect(result.target_group_id).to eq('group_sales')
  end

  it 'matches with or logic when any condition passes' do
    result = run_condition(
      'rules' => [
        {
          'id' => 'rule_1',
          'label' => 'Either',
          'logic' => 'or',
          'conditions' => [
            { 'source' => 'session_variable', 'attribute' => 'intent',
              'operator' => 'equals', 'value' => 'nope' },
            { 'source' => 'contact', 'attribute' => 'name',
              'operator' => 'equals', 'value' => 'Caio' }
          ],
          'target_group_id' => 'group_match'
        }
      ],
      'fallback_group_id' => ''
    )

    expect(result.target_group_id).to eq('group_match')
  end
end
