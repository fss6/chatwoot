# frozen_string_literal: true

require 'rails_helper'

RSpec.describe WlBotFlow, type: :model do
  let(:account) { create(:account) }
  let(:inbox) { create(:inbox, account: account) }
  let(:flow) { create(:wl_bot_flow, account: account, inbox: inbox) }

  describe '#publish!' do
    it 'publishes and creates agent bot' do
      flow.publish!
      flow.reload
      expect(flow).to be_published
      expect(flow.agent_bot).to be_present
      expect(flow.agent_bot.bot_config['managed_by']).to eq('wl_bot_flows')
      expect(inbox.reload.agent_bot).to eq(flow.agent_bot)
    end

    it 'blocks publish when wl ai assistant is linked' do
      assistant = WlAiAssistant.create!(account: account, name: 'Test assistant', description: 'Test')
      WlAiAssistantInbox.create!(wl_ai_assistant: assistant, inbox: inbox)

      expect { flow.publish! }.to raise_error(WlBotFlows::PublishError)
    end
  end
end
