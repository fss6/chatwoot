# frozen_string_literal: true

module WlBotFlows
  class ConditionFieldResolver
    CONTACT_ATTRIBUTES = %w[name email phone_number].freeze
    CONVERSATION_ATTRIBUTES = %w[labels].freeze
    INBOX_ATTRIBUTES = %w[working_now].freeze
    DATETIME_ATTRIBUTES = %w[hour day_of_week date].freeze

    def initialize(session:)
      @session = session
    end

    def resolve(condition)
      condition = condition.stringify_keys
      source = condition['source']
      attribute = condition['attribute']

      case source
      when 'session_variable'
        (@session.variables || {})[attribute]
      when 'contact'
        resolve_contact_attribute(attribute)
      when 'conversation'
        resolve_conversation_attribute(attribute)
      when 'inbox'
        resolve_inbox_attribute(attribute)
      when 'datetime'
        resolve_datetime_attribute(attribute)
      else
        # Legacy: bare field on rule without source
        (@session.variables || {})[condition['field'] || attribute]
      end
    end

    private

    def resolve_contact_attribute(attribute)
      contact = @session.conversation&.contact
      return nil if contact.blank?

      if attribute.start_with?('custom_attribute:')
        key = attribute.delete_prefix('custom_attribute:')
        return (contact.custom_attributes || {})[key]
      end

      case attribute
      when 'name' then contact.name
      when 'email' then contact.email
      when 'phone_number' then contact.phone_number
      end
    end

    def resolve_conversation_attribute(attribute)
      conv = @session.conversation
      return nil if conv.blank?

      if attribute.start_with?('custom_attribute:')
        key = attribute.delete_prefix('custom_attribute:')
        return (conv.custom_attributes || {})[key]
      end

      case attribute
      when 'labels' then conv.cached_label_list_array
      end
    end

    def resolve_inbox_attribute(attribute)
      inbox = @session.wl_bot_flow&.inbox
      return nil if inbox.blank?

      case attribute
      when 'working_now' then inbox.working_now?
      end
    end

    def resolve_datetime_attribute(attribute)
      now = Time.current
      case attribute
      when 'hour' then now.hour
      when 'day_of_week' then now.wday
      when 'date' then now.to_date.to_s
      end
    end
  end
end
