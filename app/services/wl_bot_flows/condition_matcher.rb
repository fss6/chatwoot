# frozen_string_literal: true

module WlBotFlows
  class ConditionMatcher
    OPERATORS = %w[
      equals not_equals contains not_contains
      starts_with ends_with exists not_exists
      greater_than less_than includes not_includes
    ].freeze

    def self.match?(actual, operator, expected)
      new.match?(actual, operator, expected)
    end

    def match?(actual, operator, expected)
      case operator
      when 'equals' then actual.to_s == expected.to_s
      when 'not_equals' then actual.to_s != expected.to_s
      when 'contains' then actual.to_s.include?(expected.to_s)
      when 'not_contains' then !actual.to_s.include?(expected.to_s)
      when 'starts_with' then actual.to_s.start_with?(expected.to_s)
      when 'ends_with' then actual.to_s.end_with?(expected.to_s)
      when 'exists' then actual.present?
      when 'not_exists' then actual.blank?
      when 'greater_than' then actual.to_f > expected.to_f
      when 'less_than' then actual.to_f < expected.to_f
      when 'includes' then Array(actual).map(&:to_s).include?(expected.to_s)
      when 'not_includes' then !Array(actual).map(&:to_s).include?(expected.to_s)
      else false
      end
    end
  end
end
