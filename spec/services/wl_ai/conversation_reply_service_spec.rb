# frozen_string_literal: true

require 'rails_helper'

RSpec.describe WlAi::ConversationReplyService, type: :service do
  include ActiveJob::TestHelper

  let(:account) { create(:account) }
  let(:inbox) do
    create(:inbox, account: account, channel: create(:channel_widget, account: account))
  end
  let(:assistant) do
    WlAiAssistant.create!(
      account: account,
      name: 'WL',
      description: 'Test',
      config: { 'llm_handoff_enabled' => 'true' }
    )
  end
  let(:conversation) { create(:conversation, account: account, inbox: inbox, status: :pending) }

  before do
    WlAiAccountCredential.create!(account: account, api_token: 'sk-test')
    WlAiAssistantInbox.create!(wl_ai_assistant: assistant, inbox: inbox)
    create(:message, account: account, conversation: conversation, inbox: inbox, message_type: :incoming, content: 'Hi')
    ActiveJob::Base.queue_adapter = :test
  end

  after { clear_enqueued_jobs }

  def stub_llm_reply(content)
    mock_context = double('llm_context')
    mock_chat = double('llm_chat')
    reply_obj = double('llm_reply', content: content)
    allow(Llm::Config).to receive(:with_api_key).and_yield(mock_context)
    allow(mock_context).to receive(:chat).and_return(mock_chat)
    allow(mock_chat).to receive(:with_instructions).and_return(mock_chat)
    allow(mock_chat).to receive(:add_message)
    allow(mock_chat).to receive(:ask).and_return(reply_obj)
  end

  it 'enqueues BotHandoffJob when structured reply requests handoff' do
    stub_llm_reply('{"handoff":true,"message":"One moment","reason":"User requested agent"}')

    expect do
      described_class.new(conversation: conversation, assistant: assistant).call
    end.to have_enqueued_job(WlAi::BotHandoffJob).with(
      conversation.id,
      assistant.id,
      'User requested agent',
      'llm'
    )

    expect(conversation.reload.messages.outgoing.where(sender: assistant)).to be_empty
  end

  it 'creates outgoing message when handoff is false' do
    stub_llm_reply('{"handoff":false,"message":"Hello back","reason":""}')

    expect do
      described_class.new(conversation: conversation, assistant: assistant).call
    end.not_to(have_enqueued_job(WlAi::BotHandoffJob))

    last = conversation.reload.messages.outgoing.order(:id).last
    expect(last.content).to eq('Hello back')
  end

  it 'falls back to plain text when JSON is invalid' do
    stub_llm_reply('Not json at all')

    described_class.new(conversation: conversation, assistant: assistant).call

    last = conversation.reload.messages.outgoing.order(:id).last
    expect(last.content).to eq('Not json at all')
  end
end
