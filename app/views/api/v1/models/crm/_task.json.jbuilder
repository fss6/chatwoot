json.id task.id
json.title task.title
json.description task.description
json.task_type task.task_type
json.status task.status
json.priority task.priority
json.due_at task.due_at
json.completed_at task.completed_at
json.cancelled_at task.cancelled_at
json.deal_id task.deal_id
json.contact_id task.contact_id
json.conversation_id task.conversation_id
json.is_overdue task.overdue?
json.created_at task.created_at
json.updated_at task.updated_at

if task.assigned_user.present?
  json.assigned_user do
    json.id task.assigned_user.id
    json.name task.assigned_user.name
  end
else
  json.assigned_user nil
end
