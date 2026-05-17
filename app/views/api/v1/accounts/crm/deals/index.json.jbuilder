json.payload do
  json.array! @deals, partial: 'api/v1/models/crm/deal', as: :deal
end
