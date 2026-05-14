# frozen_string_literal: true

class CreateWlAiAssistantsAndLinkFaqEntries < ActiveRecord::Migration[7.0]
  class MigrationWlAiAssistant < ApplicationRecord
    self.table_name = 'wl_ai_assistants'
  end

  class MigrationWlAiFaqEntry < ApplicationRecord
    self.table_name = 'wl_ai_faq_entries'
  end

  def up
    create_table :wl_ai_assistants do |t|
      t.references :account, null: false, foreign_key: true
      t.string :name, null: false
      t.text :description, null: false
      t.string :product_name
      t.jsonb :config, null: false, default: {}
      t.timestamps
    end

    add_reference :wl_ai_faq_entries, :wl_ai_assistant, null: true, foreign_key: true

    say_with_time 'backfill wl_ai_assistants for accounts with FAQ entries' do
      MigrationWlAiFaqEntry.distinct.pluck(:account_id).each do |account_id|
        assistant = MigrationWlAiAssistant.create!(
          account_id: account_id,
          name: 'Default assistant',
          description: 'Migrated from account-level FAQs.',
          config: {}
        )
        MigrationWlAiFaqEntry.where(account_id: account_id).update_all(wl_ai_assistant_id: assistant.id)
      end
    end

    change_column_null :wl_ai_faq_entries, :wl_ai_assistant_id, false
  end

  def down
    change_column_null :wl_ai_faq_entries, :wl_ai_assistant_id, true
    remove_reference :wl_ai_faq_entries, :wl_ai_assistant, foreign_key: true
    drop_table :wl_ai_assistants
  end
end
