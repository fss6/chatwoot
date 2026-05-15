json.execution_logs @execution_logs do |log|
  json.id log.id
  json.group_id log.group_id
  json.action_id log.action_id
  json.action_type log.action_type
  json.input log.input
  json.output log.output
  json.status log.status
  json.error_message log.error_message
  json.conversation_id log.wl_bot_session.chatwoot_conversation_id
  json.created_at log.created_at
end
json.total_count @total_count
