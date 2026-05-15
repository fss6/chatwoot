# frozen_string_literal: true

require 'rails_helper'

RSpec.describe WlBotFlows::ConditionFieldResolver do
  let(:account) { create(:account) }
  let(:inbox) { create(:inbox, account: account) }
  let(:contact) { create(:contact, account: account, name: 'Caio', email: 'caio@example.com') }
  let(:contact_inbox) { create(:contact_inbox, contact: contact, inbox: inbox) }
  let(:conversation) do
    create(:conversation, account: account, inbox: inbox, contact: contact, contact_inbox: contact_inbox)
  end
  let(:flow) { create(:wl_bot_flow, account: account, inbox: inbox) }
  let(:session) do
    WlBotSession.create!(
      wl_bot_flow: flow,
      chatwoot_account_id: account.id,
      chatwoot_conversation_id: conversation.id,
      variables: { 'intent' => 'sales' },
      status: :active
    )
  end

  subject(:resolver) { described_class.new(session: session) }

  it 'resolves session variables' do
    value = resolver.resolve(
      'source' => 'session_variable', 'attribute' => 'intent'
    )
    expect(value).to eq('sales')
  end

  it 'resolves contact name' do
    value = resolver.resolve(
      'source' => 'contact', 'attribute' => 'name'
    )
    expect(value).to eq('Caio')
  end
end
