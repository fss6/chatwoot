# frozen_string_literal: true

module WlBotFlows
  module Actions
    class SetCustomAttribute < Base
      def call
        key = @data[:key].to_s
        value = @interpolator.interpolate(@data[:value])
        target = @data[:target].to_s

        case target
        when 'contact'
          contact = conversation&.contact
          return Result.failed('Contact not found') if contact.blank?

          attrs = (contact.custom_attributes || {}).merge(key => value)
          contact.update!(custom_attributes: attrs)
        else
          return Result.failed('Conversation not found') if conversation.blank?

          attrs = (conversation.custom_attributes || {}).merge(key => value)
          conversation.update!(custom_attributes: attrs)
        end

        Result.continue
      rescue StandardError => e
        Result.failed(e.message)
      end
    end
  end
end
