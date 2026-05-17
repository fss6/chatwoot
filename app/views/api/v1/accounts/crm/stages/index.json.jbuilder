json.payload do
  json.array! @stages, partial: 'api/v1/models/crm/stage', as: :stage
end
