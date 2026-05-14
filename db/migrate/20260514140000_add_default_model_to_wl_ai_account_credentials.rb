class AddDefaultModelToWlAiAccountCredentials < ActiveRecord::Migration[7.0]
  def change
    add_column :wl_ai_account_credentials, :default_model, :string
  end
end
