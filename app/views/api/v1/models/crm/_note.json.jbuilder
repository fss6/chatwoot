json.id note.id
json.content note.content
json.deal_id note.deal_id
json.account_id note.account_id

if note.user.present?
  json.user do
    json.partial! 'api/v1/models/agent', formats: [:json], resource: note.user
  end
else
  json.user nil
end

json.created_at note.created_at.to_i
json.updated_at note.updated_at.to_i
