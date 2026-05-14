class CreateWlAiAccountCredentials < ActiveRecord::Migration[7.0]
  def change
    create_table :wl_ai_account_credentials do |t|
      t.integer :account_id, null: false
      t.string :api_base
      t.string :api_token

      t.timestamps
    end

    add_index :wl_ai_account_credentials, :account_id, unique: true
    add_foreign_key :wl_ai_account_credentials, :accounts
  end
end
