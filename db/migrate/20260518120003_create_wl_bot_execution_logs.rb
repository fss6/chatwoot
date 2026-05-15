# frozen_string_literal: true

class CreateWlBotExecutionLogs < ActiveRecord::Migration[7.1]
  def change
    create_table :wl_bot_execution_logs do |t|
      t.references :wl_bot_session, null: false, foreign_key: true

      t.string :group_id
      t.string :action_id
      t.string :action_type

      t.jsonb :input, null: false, default: {}
      t.jsonb :output, null: false, default: {}

      t.integer :status, null: false, default: 0
      t.text :error_message

      t.timestamps
    end

    add_index :wl_bot_execution_logs, %i[wl_bot_session_id created_at]
  end
end
