# frozen_string_literal: true

FactoryBot.define do
  factory :wl_bot_flow do
    account
    sequence(:name) { |n| "Bot flow #{n}" }
    status { :draft }
    draft_json do
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
    published_json { {} }
  end
end
