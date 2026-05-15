# frozen_string_literal: true

require 'rails_helper'

RSpec.describe WlAi::BotHandoffJob, type: :job do
  let(:account) { create(:account) }
  let(:inbox) do
    create(:inbox, account: account, channel: create(:channel_widget, account: account))
  end
  let(:assistant) do
    WlAiAssistant.create!(
      account: account,
      name: 'WL',
      description: 'Test',
      config: { 'handoff_message' => 'Custom handoff line' }
    )
  end
  let(:conversation) { create(:conversation, account: account, inbox: inbox, status: :pending) }

  before do
    WlAiAssistantInbox.create!(wl_ai_assistant: assistant, inbox: inbox)
  end

  it 'creates private note, public handoff message, and opens conversation' do
    described_class.perform_now(conversation.id, assistant.id, 'User asked for human', 'keyword')

    conversation.reload
    expect(conversation.status).to eq('open')

    priv = conversation.messages.outgoing.find_by(private: true)
    expect(priv).to be_present
    expect(priv.content).to include('User asked for human')
    expect(priv.sender).to eq(assistant)

    pub = conversation.messages.outgoing.where(private: false).order(:id).last
    expect(pub.content).to eq('Custom handoff line')
    expect(pub.sender).to eq(assistant)
  end

  it 'uses i18n default when handoff_message is blank' do
    assistant.update!(config: {})
    described_class.perform_now(conversation.id, assistant.id, nil, 'keyword')

    conversation.reload
    pub = conversation.messages.outgoing.where(private: false).order(:id).last
    expect(pub.content).to eq(I18n.t('conversations.wl_ai.handoff', locale: account.locale))
  end

  it 'skips private note when reason is blank' do
    described_class.perform_now(conversation.id, assistant.id, nil, 'keyword')

    expect(conversation.reload.messages.outgoing.where(private: true)).to be_empty
  end

  it 'does nothing when conversation is not pending' do
    conversation.update!(status: :open)
    expect do
      described_class.perform_now(conversation.id, assistant.id, 'x', 'keyword')
    end.not_to(change { conversation.reload.messages.count })
  end
end
