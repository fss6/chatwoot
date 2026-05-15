# frozen_string_literal: true

module WlBotFlows
  module Actions
    class Condition < Base
      def call
        rules = @data[:rules] || []
        resolver = ConditionFieldResolver.new(session: @session)

        rules.each do |rule|
          next unless rule_matches?(rule, resolver)

          target = rule['target_group_id']
          return Result.go_to(target) if target.present?
        end

        fallback = @data['fallback_group_id']
        return Result.go_to(fallback) if fallback.present?

        Result.continue
      end

      private

      def rule_matches?(rule, resolver)
        conditions = normalized_conditions(rule)
        return false if conditions.empty?

        logic = rule['logic'].presence || 'and'
        results = conditions.map { |c| condition_matches?(c, resolver) }

        logic == 'or' ? results.any? : results.all?
      end

      def normalized_conditions(rule)
        if rule['conditions'].present?
          rule['conditions']
        elsif rule['field'].present?
          [{ 'source' => 'session_variable', 'attribute' => rule['field'],
             'operator' => rule['operator'], 'value' => rule['value'] }]
        else
          []
        end
      end

      def condition_matches?(condition, resolver)
        operator = condition['operator']
        return false if operator.blank?

        actual = resolver.resolve(condition)
        ConditionMatcher.match?(actual, operator, condition['value'])
      end
    end
  end
end
