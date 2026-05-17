json.payload do
  json.array! @activities, partial: 'api/v1/models/crm/activity', as: :activity
end
