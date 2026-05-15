# frozen_string_literal: true

require 'rails_helper'

RSpec.describe WlAi::HumanTransferIntentDetector do
  let(:account) { create(:account) }
  let(:assistant) do
    WlAiAssistant.create!(
      account: account,
      name: 'WL',
      description: 'Test',
      config: { 'transfer_keywords' => %w[banana] }
    )
  end
  let(:conversation) { create(:conversation, account: account, status: :pending) }
  let(:inbox) { conversation.inbox }

  def message_with(content)
    build(:message, account: account, conversation: conversation, inbox: inbox, message_type: :incoming, content: content)
  end

  it 'matches configured keyword (substring)' do
    expect(described_class.match?(message_with('I want a BANANA please'), assistant)).to be true
  end

  it 'does not match unrelated text' do
    expect(described_class.match?(message_with('Only apples here'), assistant)).to be false
  end

  it 'respects whole_word mode' do
    assistant.update!(config: { 'transfer_keywords' => %w[human], 'transfer_match_mode' => 'whole_word' })
    expect(described_class.match?(message_with('I need a human'), assistant)).to be true
    expect(described_class.match?(message_with('humano por favor'), assistant)).to be false
  end

  it 'uses i18n default keywords when transfer_keywords is empty' do
    assistant.update!(config: {})
    expect(described_class.keywords_for(assistant)).to include('human')
    expect(described_class.match?(message_with('Can I speak to a human please?'), assistant)).to be true
  end

  it 'returns false for private incoming messages' do
    m = build(:message, account: account, conversation: conversation, inbox: inbox, message_type: :incoming,
                        private: true, content: 'banana')
    expect(described_class.match?(m, assistant)).to be false
  end
end
