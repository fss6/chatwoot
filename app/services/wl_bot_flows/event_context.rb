# frozen_string_literal: true

module WlBotFlows
  class EventContext
    attr_reader :payload, :event_name

    def initialize(payload)
      @payload = payload.with_indifferent_access
      @event_name = @payload[:event]
    end

    def message_event?
      %w[message_created message_updated].include?(event_name)
    end

    def account_id
      payload.dig(:account, :id) || payload.dig(:conversation, :account_id)
    end

    def inbox_id
      payload.dig(:inbox, :id) || payload.dig(:conversation, :inbox_id)
    end

    def conversation_id
      payload.dig(:conversation, :id)
    end

    def contact_id
      payload.dig(:conversation, :contact_inbox, :contact_id) ||
        payload.dig(:sender, :id)
    end

    def message_content
      payload[:content].to_s
    end

    def incoming_message?
      mt = payload[:message_type]
      mt == 'incoming' || mt == 0 || mt.to_s == '0'
    end

    def agent_bot_sender?(agent_bot_id)
      sender = payload[:sender]
      return false if sender.blank?

      sender[:type].to_s == 'agent_bot' && sender[:id].to_i == agent_bot_id.to_i
    end
  end
end
