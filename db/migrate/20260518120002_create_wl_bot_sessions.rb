# frozen_string_literal: true

class CreateWlBotSessions < ActiveRecord::Migration[7.1]
  def change
    create_table :wl_bot_sessions do |t|
      t.references :wl_bot_flow, null: false, foreign_key: true

      t.bigint :chatwoot_account_id, null: false
      t.bigint :chatwoot_conversation_id, null: false
      t.bigint :chatwoot_contact_id

      t.string :current_group_id
      t.integer :current_action_index, null: false, default: 0
      t.integer :status, null: false, default: 0

      t.jsonb :variables, null: false, default: {}

      t.datetime :waiting_since
      t.datetime :timeout_at
      t.datetime :finished_at
      t.datetime :transferred_at

      t.timestamps
    end

    add_index :wl_bot_sessions,
              %i[chatwoot_account_id chatwoot_conversation_id],
              unique: true,
              name: 'index_wl_bot_sessions_on_account_and_conversation'
    add_index :wl_bot_sessions, %i[wl_bot_flow_id status]
  end
end
