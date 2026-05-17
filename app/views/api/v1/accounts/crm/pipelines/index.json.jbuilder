json.payload do
  json.array! @pipelines, partial: 'api/v1/models/crm/pipeline', as: :pipeline
end
