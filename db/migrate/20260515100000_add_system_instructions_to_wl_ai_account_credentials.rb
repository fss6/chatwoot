class AddSystemInstructionsToWlAiAccountCredentials < ActiveRecord::Migration[7.0]
  def change
    add_column :wl_ai_account_credentials, :system_instructions, :text
  end
end
