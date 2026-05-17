json.id pipeline.id
json.name pipeline.name
json.description pipeline.description
json.position pipeline.position
json.active pipeline.active
json.created_at pipeline.created_at
json.updated_at pipeline.updated_at

if pipeline.stages.loaded? || pipeline.stages.any?
  json.stages pipeline.stages.active.ordered do |stage|
    json.partial! 'api/v1/models/crm/stage', stage: stage
  end
end
