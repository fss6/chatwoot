# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'WL AI MessageTemplates::HookExecutionService integration', type: :model do
  include ActiveJob::TestHelper

  around do |example|
    with_modified_env('WL_AI_AUTO_REPLY' => 'true') { example.run }
  end

  before { ActiveJob::Base.queue_adapter = :test }

  after { clear_enqueued_jobs }

  it 'enqueues WlAi::IncomingReplyJob when conversation is pending and inbox has WL assistant' do
    account = create(:account)
    WlAiAccountCredential.create!(account: account, api_token: 'sk-test')
    assistant = WlAiAssistant.create!(
      account: account,
      name: 'WL Bot',
      description: 'Test assistant',
      config: {}
    )
    conversation = create(:conversation, account: account, status: :pending)
    inbox = conversation.inbox
    WlAiAssistantInbox.create!(wl_ai_assistant: assistant, inbox: inbox)

    message = create(
      :message,
      account: account,
      conversation: conversation,
      inbox: inbox,
      message_type: :incoming,
      content: 'Hello from customer'
    )

    expect do
      MessageTemplates::HookExecutionService.new(message: message).perform
    end.to have_enqueued_job(WlAi::IncomingReplyJob).with(conversation.id, assistant.id)
  end

  it 'enqueues BotHandoffJob instead of IncomingReplyJob when transfer intent matches' do
    account = create(:account)
    WlAiAccountCredential.create!(account: account, api_token: 'sk-test')
    assistant = WlAiAssistant.create!(
      account: account,
      name: 'WL Bot',
      description: 'Test assistant',
      config: {}
    )
    conversation = create(:conversation, account: account, status: :pending)
    inbox = conversation.inbox
    WlAiAssistantInbox.create!(wl_ai_assistant: assistant, inbox: inbox)

    message = create(
      :message,
      account: account,
      conversation: conversation,
      inbox: inbox,
      message_type: :incoming,
      content: 'Please connect me to a human agent'
    )

    expect do
      MessageTemplates::HookExecutionService.new(message: message).perform
    end.to have_enqueued_job(WlAi::BotHandoffJob).with(
      conversation.id,
      assistant.id,
      anything,
      'keyword'
    )

    expect(ActiveJob::Base.queue_adapter.enqueued_jobs.map { |j| j[:job] }).not_to include(WlAi::IncomingReplyJob)
  end

  it 'enqueues BotHandoffJob on transfer intent without LLM credentials' do
    account = create(:account)
    assistant = WlAiAssistant.create!(
      account: account,
      name: 'WL Bot',
      description: 'Test assistant',
      config: {}
    )
    conversation = create(:conversation, account: account, status: :pending)
    inbox = conversation.inbox
    WlAiAssistantInbox.create!(wl_ai_assistant: assistant, inbox: inbox)

    message = create(
      :message,
      account: account,
      conversation: conversation,
      inbox: inbox,
      message_type: :incoming,
      content: 'I need a human'
    )

    expect do
      MessageTemplates::HookExecutionService.new(message: message).perform
    end.to have_enqueued_job(WlAi::BotHandoffJob)

    expect(ActiveJob::Base.queue_adapter.enqueued_jobs.map { |j| j[:job] }).not_to include(WlAi::IncomingReplyJob)
  end

  it 'does not enqueue when WL_AI_AUTO_REPLY is not true' do
    account = create(:account)
    WlAiAccountCredential.create!(account: account, api_token: 'sk-test')
    assistant = WlAiAssistant.create!(
      account: account,
      name: 'WL Bot',
      description: 'Test assistant',
      config: {}
    )
    conversation = create(:conversation, account: account, status: :pending)
    inbox = conversation.inbox
    WlAiAssistantInbox.create!(wl_ai_assistant: assistant, inbox: inbox)
    message = create(
      :message,
      account: account,
      conversation: conversation,
      inbox: inbox,
      message_type: :incoming
    )

    with_modified_env('WL_AI_AUTO_REPLY' => 'false') do
      expect do
        MessageTemplates::HookExecutionService.new(message: message).perform
      end.not_to have_enqueued_job(WlAi::IncomingReplyJob)
    end
  end
end
