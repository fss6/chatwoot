class CreateWlAiFaqEntries < ActiveRecord::Migration[7.0]
  def change
    create_table :wl_ai_faq_entries do |t|
      t.integer :account_id, null: false
      t.string :question, null: false
      t.text :answer, null: false
      t.integer :position, null: false, default: 0

      t.timestamps
    end

    add_index :wl_ai_faq_entries, :account_id
    add_foreign_key :wl_ai_faq_entries, :accounts
  end
end
