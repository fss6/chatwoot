# frozen_string_literal: true

module WlBotFlows
  class Validator
    class ValidationError < StandardError; end

    CONDITION_SOURCES = %w[session_variable contact conversation inbox datetime].freeze
    CONTACT_ATTRIBUTES = ConditionFieldResolver::CONTACT_ATTRIBUTES
    CONVERSATION_ATTRIBUTES = ConditionFieldResolver::CONVERSATION_ATTRIBUTES
    INBOX_ATTRIBUTES = ConditionFieldResolver::INBOX_ATTRIBUTES
    DATETIME_ATTRIBUTES = ConditionFieldResolver::DATETIME_ATTRIBUTES
    CONDITION_OPERATORS = ConditionMatcher::OPERATORS
    VALUE_OPTIONAL_OPERATORS = %w[exists not_exists].freeze

    def initialize(flow_json, publish: false)
      @flow = flow_json.deep_stringify_keys
      @publish = publish
    end

    def validate!
      raise ValidationError, 'Flow is empty' if @flow.blank?

      entry = @flow['entry_group_id']
      raise ValidationError, 'entry_group_id is required' if entry.blank?

      groups = @flow['groups'] || []
      raise ValidationError, 'At least one group is required' if groups.empty?

      group_ids = groups.map { |g| g['id'] }.compact
      raise ValidationError, 'Duplicate group ids' if group_ids.uniq.length != group_ids.length

      raise ValidationError, 'entry_group_id must reference an existing group' unless group_ids.include?(entry)

      groups.each { |g| validate_group!(g, group_ids) }
      validate_edges!(group_ids)
    end

    private

    def validate_group!(group, group_ids)
      raise ValidationError, 'Group id is required' if group['id'].blank?
      raise ValidationError, 'Group name is required' if group['name'].blank?
      raise ValidationError, 'Group position is required' if group['position'].blank?

      actions = group['actions'] || []
      action_ids = actions.map { |a| a['id'] }.compact
      raise ValidationError, "Duplicate action ids in group #{group['id']}" if action_ids.uniq.length != action_ids.length

      validate_target_group!(group['next_group_id'], group_ids) if group['next_group_id'].present?

      actions.each { |a| validate_action!(a, group_ids) }
    end

    def validate_action!(action, group_ids)
      raise ValidationError, 'Action type is required' if action['type'].blank?
      raise ValidationError, 'Action data is required' if action['data'].nil?

      case action['type']
      when 'condition'
        validate_condition!(action['data'], group_ids)
      when 'go_to_group'
        validate_target_group!(action.dig('data', 'target_group_id'), group_ids)
      when 'transfer_to_team'
        raise ValidationError, 'team_id is required' if action.dig('data', 'team_id').blank?
      when 'assign_agent'
        raise ValidationError, 'agent_id is required' if action.dig('data', 'agent_id').blank?
      when 'send_webhook'
        url = action.dig('data', 'url')
        raise ValidationError, 'webhook url is required' if url.blank?
        raise ValidationError, 'invalid webhook url' unless url.match?(%r{\Ahttps?://}i)
        validate_target_group!(action.dig('data', 'success_group_id'), group_ids)
        validate_target_group!(action.dig('data', 'failure_group_id'), group_ids)
      when 'ask'
        validate_ask!(action['data'], group_ids)
      end
    end

    def validate_ask!(data, group_ids)
      raise ValidationError, 'ask text is required' if data['text'].blank?

      subtype = data['subtype'].presence || 'text'
      raise ValidationError, "invalid ask subtype: #{subtype}" unless %w[text buttons list].include?(subtype)

      if subtype != 'text'
        options = data['options'] || []
        raise ValidationError, 'ask buttons/list requires at least one option' if options.empty?

        options.each do |opt|
          raise ValidationError, 'ask option id is required' if opt['id'].blank?
          raise ValidationError, 'ask option label is required' if opt['label'].blank?
        end
      end

      validate_target_group!(data['timeout_group_id'], group_ids)
      validate_target_group!(data['invalid_response_group_id'], group_ids)
    end

    def validate_condition!(data, group_ids)
      rules = data['rules'] || []
      fallback = data['fallback_group_id']

      raise ValidationError, 'condition requires at least one rule or a fallback' if rules.empty? && fallback.blank?
      raise ValidationError, 'condition fallback_group_id is required when publishing' if @publish && fallback.blank?

      rule_ids = rules.map { |r| r['id'] }.compact
      raise ValidationError, 'duplicate condition rule ids' if rule_ids.uniq.length != rule_ids.length

      rules.each { |rule| validate_condition_rule!(rule, group_ids) }
      validate_target_group!(fallback, group_ids) if fallback.present?
    end

    def validate_condition_rule!(rule, group_ids)
      raise ValidationError, 'condition rule id is required' if rule['id'].blank?
      raise ValidationError, 'condition rule label is required' if rule['label'].blank?

      validate_target_group!(rule['target_group_id'], group_ids)
      raise ValidationError, 'condition rule target_group_id is required' if rule['target_group_id'].blank?

      conditions = normalized_rule_conditions(rule)
      raise ValidationError, 'condition rule requires at least one condition' if conditions.empty?

      conditions.each { |c| validate_condition_clause!(c) }
    end

    def normalized_rule_conditions(rule)
      if rule['conditions'].present?
        rule['conditions']
      elsif rule['field'].present?
        [{ 'source' => 'session_variable', 'attribute' => rule['field'],
           'operator' => rule['operator'], 'value' => rule['value'] }]
      else
        []
      end
    end

    def validate_condition_clause!(condition)
      source = condition['source'].presence || 'session_variable'
      raise ValidationError, "invalid condition source: #{source}" unless CONDITION_SOURCES.include?(source)

      attribute = condition['attribute']
      raise ValidationError, 'condition attribute is required' if attribute.blank?

      validate_source_attribute!(source, attribute)

      operator = condition['operator']
      raise ValidationError, 'condition operator is required' if operator.blank?
      raise ValidationError, "invalid condition operator: #{operator}" unless CONDITION_OPERATORS.include?(operator)

      return if VALUE_OPTIONAL_OPERATORS.include?(operator)

      raise ValidationError, 'condition value is required' if condition['value'].nil?
    end

    def validate_source_attribute!(source, attribute)
      case source
      when 'contact'
        return if attribute.start_with?('custom_attribute:')
        raise ValidationError, "invalid contact attribute: #{attribute}" unless CONTACT_ATTRIBUTES.include?(attribute)
      when 'conversation'
        return if attribute.start_with?('custom_attribute:')
        raise ValidationError, "invalid conversation attribute: #{attribute}" unless CONVERSATION_ATTRIBUTES.include?(attribute)
      when 'inbox'
        raise ValidationError, "invalid inbox attribute: #{attribute}" unless INBOX_ATTRIBUTES.include?(attribute)
      when 'datetime'
        raise ValidationError, "invalid datetime attribute: #{attribute}" unless DATETIME_ATTRIBUTES.include?(attribute)
      end
    end

    def validate_target_group!(target_id, group_ids)
      return if target_id.blank?

      raise ValidationError, "Unknown group #{target_id}" unless group_ids.include?(target_id)
    end

    def validate_edges!(group_ids)
      (@flow['edges'] || []).each do |edge|
        validate_target_group!(edge['source'], group_ids)
        validate_target_group!(edge['target'], group_ids)
      end
    end
  end
end
