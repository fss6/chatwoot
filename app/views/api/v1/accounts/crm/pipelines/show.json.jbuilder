json.payload do
  json.partial! 'api/v1/models/crm/pipeline', pipeline: @pipeline
end
