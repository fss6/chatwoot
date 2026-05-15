# frozen_string_literal: true

module WlBotFlows
  class VariableInterpolator
    def initialize(session:, context:)
      @session = session
      @context = context
    end

    def interpolate(value)
      return value unless value.is_a?(String)

      value.gsub(/\{\{(\w+)\}\}/) do |_match|
        key = Regexp.last_match(1)
        resolve_key(key)
      end
    end

    def interpolate_hash(hash)
      return hash unless hash.is_a?(Hash)

      hash.transform_values { |v| interpolate_deep(v) }
    end

    private

    def interpolate_deep(obj)
      case obj
      when String then interpolate(obj)
      when Hash then obj.transform_values { |v| interpolate_deep(v) }
      when Array then obj.map { |v| interpolate_deep(v) }
      else obj
      end
    end

    def resolve_key(key)
      case key
      when 'conversation_id' then @context.conversation_id.to_s
      when 'contact_id' then @context.contact_id.to_s
      when 'variables' then (@session.variables || {}).to_json
      else
        (@session.variables || {})[key].to_s
      end
    end
  end
end
