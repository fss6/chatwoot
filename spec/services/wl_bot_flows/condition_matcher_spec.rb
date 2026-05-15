# frozen_string_literal: true

require 'rails_helper'

RSpec.describe WlBotFlows::ConditionMatcher do
  describe '.match?' do
    it 'matches equals' do
      expect(described_class.match?('hello', 'equals', 'hello')).to be true
    end

    it 'matches exists' do
      expect(described_class.match?('x', 'exists', nil)).to be true
      expect(described_class.match?('', 'exists', nil)).to be false
    end
  end
end
