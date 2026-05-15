# frozen_string_literal: true

module WlBotFlows
  class Runtime
    MAX_STEPS_PER_EVENT = 10

    def initialize(bot_flow:, session:, context:, agent_bot:, event_payload: nil)
      @bot_flow = bot_flow
      @session = session
      @context = context
      @agent_bot = agent_bot
      @event_payload = event_payload
      @flow = bot_flow.published_json.deep_stringify_keys
    end

    def call
      return if terminal_session?

      save_input_if_waiting!

      steps = 0
      while steps < MAX_STEPS_PER_EVENT
        group = current_group
        action = current_action(group)
        if action.blank?
          break follow_group_exit!(group) if group.present?

          break finish_session!
        end

        result = ActionRunner.new(
          action: action,
          session: @session,
          context: @context,
          flow: @flow,
          agent_bot: @agent_bot
        ).call

        log_execution(action, result)

        case result.status
        when :continue
          advance_action!(group)
        when :wait
          schedule_wait_continuation!(result.wait_seconds) if result.wait_seconds.present?
          break
        when :go_to_group
          move_to_group!(result.target_group_id)
        when :finish
          finish_session!
          break
        when :transfer
          break
        when :failed
          fail_session!(result.error)
          break
        end

        steps += 1
      end
    end

    private

    def terminal_session?
      @session.finished? || @session.transferred_to_human? || @session.paused? || @session.failed?
    end

    def save_input_if_waiting!
      return unless @session.waiting_contact_message? && @context.incoming_message?

      group = find_group(@session.current_group_id)
      return if group.blank?

      action = (group['actions'] || [])[@session.current_action_index]
      return if action.blank?

      if action['type'] == 'ask'
        handle_ask_response!(action)
      elsif action['type'] == 'wait_for_contact_message'
        handle_wait_response!(action)
      end
    end

    def handle_ask_response!(action)
      data = (action['data'] || {}).with_indifferent_access
      content = @context.message_content.to_s.strip
      subtype = data[:subtype].presence || 'text'
      save_as = data[:save_as]

      if subtype != 'text'
        options = data[:options] || []
        valid_ids = options.map { |o| o['id'].to_s }
        valid_labels = options.map { |o| o['label'].to_s }

        unless valid_ids.include?(content) || valid_labels.include?(content)
          invalid_group = data[:invalid_response_group_id]
          if invalid_group.present?
            @session.update!(status: :active, waiting_since: nil, timeout_at: nil)
            move_to_group!(invalid_group)
          else
            @session.update!(status: :active, waiting_since: nil, timeout_at: nil,
                             current_action_index: @session.current_action_index)
          end
          return
        end
      end

      vars = (@session.variables || {})
      vars = vars.merge(save_as => content) if save_as.present?
      @session.update!(
        variables: vars,
        status: :active,
        waiting_since: nil,
        timeout_at: nil,
        current_action_index: @session.current_action_index + 1
      )
    end

    def handle_wait_response!(action)
      save_as = action.dig('data', 'save_as')
      vars = (@session.variables || {})
      vars = vars.merge(save_as => @context.message_content) if save_as.present?
      @session.update!(
        variables: vars,
        status: :active,
        waiting_since: nil,
        timeout_at: nil,
        current_action_index: @session.current_action_index + 1
      )
    end

    def current_group
      find_group(@session.current_group_id) || find_group(@flow['entry_group_id'])
    end

    def current_action(group)
      return nil if group.blank?

      actions = group['actions'] || []
      actions[@session.current_action_index]
    end

    def find_group(group_id)
      (@flow['groups'] || []).find { |g| g['id'] == group_id }
    end

    def advance_action!(group)
      actions = group['actions'] || []
      next_index = @session.current_action_index + 1
      if next_index >= actions.length
        follow_group_exit!(group)
      else
        @session.update!(current_action_index: next_index)
      end
    end

    def follow_group_exit!(group)
      next_id = group['next_group_id']
      if next_id.present?
        move_to_group!(next_id)
      else
        finish_session!
      end
    end

    def move_to_group!(target_group_id)
      @session.update!(current_group_id: target_group_id, current_action_index: 0)
    end

    def finish_session!
      @session.update!(status: :finished, finished_at: Time.current) unless @session.transferred_to_human?
    end

    def fail_session!(error)
      @session.update!(status: :failed)
      Rails.logger.warn("[WlBotFlows::Runtime] session=#{@session.id} error=#{error}")
    end

    def schedule_wait_continuation!(seconds)
      WlBotFlows::ProcessEventJob.set(wait: seconds.seconds).perform_later(
        @agent_bot.id,
        synthetic_continue_payload
      )
    end

    def synthetic_continue_payload
      {
        event: 'wl_bot_flow_continue',
        conversation: { id: @context.conversation_id, account_id: @context.account_id },
        account: { id: @context.account_id },
        inbox: { id: @context.inbox_id }
      }
    end

    def log_execution(action, result)
      @session.wl_bot_execution_logs.create!(
        group_id: @session.current_group_id,
        action_id: action['id'],
        action_type: action['type'],
        input: action['data'] || {},
        output: { status: result.status.to_s, target_group_id: result.target_group_id, error: result.error },
        status: result.status == :failed ? :failed : :success,
        error_message: result.error
      )
    end
  end
end
