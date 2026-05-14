# frozen_string_literal: true

class CreateWlAiAssistantInboxes < ActiveRecord::Migration[7.0]
  def change
    create_table :wl_ai_assistant_inboxes do |t|
      t.references :wl_ai_assistant, null: false, foreign_key: true
      t.references :inbox, null: false, foreign_key: true

      t.timestamps
    end

    add_index :wl_ai_assistant_inboxes,
              %i[wl_ai_assistant_id inbox_id],
              unique: true,
              name: 'index_wl_ai_assistant_inboxes_on_assistant_and_inbox'
  end
end
