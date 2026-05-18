class CreateCrmNotes < ActiveRecord::Migration[7.1]
  def change
    create_table :crm_notes do |t|
      t.references :account, null: false, foreign_key: true, index: true
      t.references :deal, null: false, foreign_key: { to_table: :crm_deals }
      t.references :user, foreign_key: true
      t.text :content, null: false

      t.timestamps
    end

    add_index :crm_notes, [:account_id, :deal_id, :created_at]
  end
end
