# frozen_string_literal: true

module WlBotFlows
  module Actions
    class SendWebhook < Base
      DEFAULT_TIMEOUT = 20

      def call
        if @data[:wait_response]
          call_sync
        else
          call_async
        end
      end

      private

      def call_async
        url = @interpolator.interpolate(@data[:url].to_s)
        body = @interpolator.interpolate_hash(@data[:body] || {})
        payload = body.merge(event: 'wl_bot_flow_webhook', conversation_id: @context.conversation_id)
        WebhookJob.perform_later(url, payload)
        Result.continue
      rescue StandardError => e
        Rails.logger.warn("[WlBotFlows::SendWebhook] #{e.message}")
        Result.continue
      end

      def call_sync
        url = @interpolator.interpolate(@data[:url].to_s)
        body = @interpolator.interpolate_hash(@data[:body] || {})
        payload = body.merge(event: 'wl_bot_flow_webhook', conversation_id: @context.conversation_id)
        method = @data[:method]&.upcase.presence || 'POST'
        timeout = @data[:timeout_seconds].to_i.positive? ? @data[:timeout_seconds].to_i : DEFAULT_TIMEOUT

        response = perform_sync_request(url, method, payload, timeout)
        success = response.status >= 200 && response.status < 300

        success_group = @data[:success_group_id]
        failure_group = @data[:failure_group_id]

        if success
          success_group.present? ? Result.go_to(success_group) : Result.continue
        else
          failure_group.present? ? Result.go_to(failure_group) : Result.failed("webhook returned #{response.status}")
        end
      rescue Faraday::TimeoutError, Faraday::ConnectionFailed => e
        Rails.logger.warn("[WlBotFlows::SendWebhook] sync timeout/error: #{e.message}")
        failure_group = @data[:failure_group_id]
        failure_group.present? ? Result.go_to(failure_group) : Result.failed('webhook timeout')
      rescue StandardError => e
        Rails.logger.warn("[WlBotFlows::SendWebhook] sync error: #{e.message}")
        failure_group = @data[:failure_group_id]
        failure_group.present? ? Result.go_to(failure_group) : Result.failed(e.message)
      end

      def perform_sync_request(url, method, payload, timeout)
        conn = Faraday.new do |f|
          f.options.timeout = timeout
          f.options.open_timeout = [timeout, 10].min
          f.request :json
          f.response :raise_error
          f.adapter Faraday.default_adapter
        end

        case method
        when 'GET'
          conn.get(url) { |req| req.params = payload }
        when 'PUT'
          conn.put(url, payload)
        when 'PATCH'
          conn.patch(url, payload)
        else
          conn.post(url, payload)
        end
      rescue Faraday::BadResponseError => e
        e.response
      end
    end
  end
end
