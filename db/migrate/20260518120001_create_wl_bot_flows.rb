# frozen_string_literal: true

class CreateWlBotFlows < ActiveRecord::Migration[7.1]
  def change
    create_table :wl_bot_flows do |t|
      t.references :account, null: false, foreign_key: true
      t.references :inbox, null: true, foreign_key: true
      t.references :agent_bot, null: true, foreign_key: true

      t.string :name, null: false
      t.integer :status, null: false, default: 0

      t.jsonb :draft_json, null: false, default: {}
      t.jsonb :published_json, null: false, default: {}
      t.integer :published_version, null: false, default: 0

      t.bigint :created_by_id
      t.bigint :updated_by_id

      t.datetime :published_at

      t.timestamps
    end

    add_index :wl_bot_flows, %i[account_id status]
    add_index :wl_bot_flows, %i[account_id inbox_id]
  end
end
