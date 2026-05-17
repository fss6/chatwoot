json.id deal.id
json.title deal.title
json.description deal.description
json.amount deal.amount
json.currency deal.currency
json.status deal.status
json.source deal.source
json.lead_temperature deal.lead_temperature
json.expected_close_date deal.expected_close_date
json.closed_at deal.closed_at
json.lost_reason deal.lost_reason
json.position deal.position
json.created_at deal.created_at
json.updated_at deal.updated_at
json.no_next_step deal.no_next_step?

json.pipeline do
  json.id deal.pipeline.id
  json.name deal.pipeline.name
end

json.stage do
  json.id deal.stage.id
  json.name deal.stage.name
  json.stage_type deal.stage.stage_type
end

json.contact do
  json.id deal.contact.id
  json.name deal.contact.name
  json.email deal.contact.email
  json.phone_number deal.contact.phone_number
  json.company_name deal.contact.additional_attributes&.dig('company_name')
end

if deal.conversation.present?
  json.conversation do
    json.id deal.conversation.id
    json.display_id deal.conversation.display_id
    json.inbox_id deal.conversation.inbox_id
  end
else
  json.conversation nil
end

if deal.assigned_user.present?
  json.assigned_user do
    json.id deal.assigned_user.id
    json.name deal.assigned_user.name
  end
else
  json.assigned_user nil
end

next_task = deal.next_pending_task
if next_task
  json.next_task do
    json.id next_task.id
    json.title next_task.title
    json.due_at next_task.due_at
    json.status next_task.status
    json.is_overdue next_task.overdue?
  end
else
  json.next_task nil
end
