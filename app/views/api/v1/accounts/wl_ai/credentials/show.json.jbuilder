json.api_base @credential&.api_base
json.system_instructions @credential&.system_instructions
json.configured @credential&.api_token.present?
json.default_model @credential&.default_model
json.effective_default_model(@credential&.default_model.presence || Llm::Config::DEFAULT_MODEL)
json.available_models @available_models
if @credential&.api_token.present?
  token = @credential.api_token
  json.token_last_four token.length <= 4 ? '****' : token.last(4)
else
  json.token_last_four nil
end
