# frozen_string_literal: true

require 'rails_helper'

RSpec.describe WlBotFlows::Validator do
  let(:valid_json) do
    {
      entry_group_id: 'group_start',
      groups: [
        {
          id: 'group_start',
          name: 'Start',
          position: { x: 0, y: 0 },
          actions: [{ id: 'a1', type: 'send_message', data: { text: 'hi' } }]
        }
      ],
      edges: []
    }
  end

  it 'accepts a valid flow' do
    expect { described_class.new(valid_json).validate! }.not_to raise_error
  end

  it 'rejects missing entry_group_id' do
    json = valid_json.except(:entry_group_id)
    expect { described_class.new(json).validate! }.to raise_error(WlBotFlows::Validator::ValidationError)
  end

  it 'rejects invalid next_group_id' do
    json = valid_json.deep_dup
    json[:groups][0][:next_group_id] = 'missing_group'
    expect { described_class.new(json).validate! }.to raise_error(WlBotFlows::Validator::ValidationError, /Unknown group/)
  end

  it 'accepts valid next_group_id' do
    json = valid_json.deep_merge(
      groups: [
        {
          id: 'group_start',
          name: 'Start',
          position: { x: 0, y: 0 },
          next_group_id: 'group_b',
          actions: [{ id: 'a1', type: 'send_message', data: { text: 'hi' } }]
        },
        {
          id: 'group_b',
          name: 'Next',
          position: { x: 200, y: 0 },
          actions: []
        }
      ]
    )
    expect { described_class.new(json).validate! }.not_to raise_error
  end

  describe 'condition actions' do
    let(:condition_json) do
      valid_json.deep_merge(
        groups: [
          {
            id: 'group_start',
            name: 'Start',
            position: { x: 0, y: 0 },
            actions: [
              {
                id: 'act_cond',
                type: 'condition',
                data: {
                  rules: [
                    {
                      id: 'rule_1',
                      label: 'Branch',
                      logic: 'and',
                      conditions: [
                        {
                          source: 'contact',
                          attribute: 'name',
                          operator: 'equals',
                          value: 'Test'
                        }
                      ],
                      target_group_id: 'group_other'
                    }
                  ],
                  fallback_group_id: 'group_start'
                }
              }
            ]
          },
          {
            id: 'group_other',
            name: 'Other',
            position: { x: 200, y: 0 },
            actions: []
          }
        ]
      )
    end

    it 'accepts a valid condition' do
      expect { described_class.new(condition_json).validate! }.not_to raise_error
    end

    it 'requires fallback when publishing' do
      json = condition_json.deep_dup
      json[:groups][0][:actions][0][:data][:fallback_group_id] = ''
      expect do
        described_class.new(json, publish: true).validate!
      end.to raise_error(WlBotFlows::Validator::ValidationError, /fallback/)
    end
  end
end
