json.payload do
  json.partial! 'api/v1/models/crm/stage', stage: @stage
end
