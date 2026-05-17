json.id activity.id
json.action activity.action
json.metadata activity.metadata
json.created_at activity.created_at

if activity.actor.present?
  json.actor do
    json.id activity.actor.id
    json.name activity.actor.name
  end
else
  json.actor nil
end
