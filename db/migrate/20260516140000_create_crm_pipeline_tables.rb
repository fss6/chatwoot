class CreateCrmPipelineTables < ActiveRecord::Migration[7.1]
  def change
    create_table :crm_pipelines do |t|
      t.references :account, null: false, foreign_key: true, index: true
      t.string :name, null: false
      t.text :description
      t.integer :position, null: false, default: 0
      t.boolean :active, null: false, default: true

      t.timestamps
    end

    add_index :crm_pipelines, [:account_id, :position]
    add_index :crm_pipelines, [:account_id, :active]

    create_table :crm_stages do |t|
      t.references :account, null: false, foreign_key: true, index: true
      t.references :pipeline, null: false, foreign_key: { to_table: :crm_pipelines }
      t.string :name, null: false
      t.integer :position, null: false, default: 0
      t.integer :stage_type, null: false, default: 0
      t.string :color
      t.boolean :active, null: false, default: true

      t.timestamps
    end

    add_index :crm_stages, [:account_id, :pipeline_id, :position]
    add_index :crm_stages, [:account_id, :stage_type]

    create_table :crm_deals do |t|
      t.references :account, null: false, foreign_key: true, index: true
      t.references :pipeline, null: false, foreign_key: { to_table: :crm_pipelines }
      t.references :stage, null: false, foreign_key: { to_table: :crm_stages }
      t.references :contact, null: false, foreign_key: true
      t.references :conversation, foreign_key: true
      t.references :assigned_user, foreign_key: { to_table: :users }

      t.string :title, null: false
      t.text :description
      t.decimal :amount, precision: 12, scale: 2
      t.string :currency, null: false, default: 'BRL'
      t.integer :status, null: false, default: 0
      t.string :source
      t.integer :lead_temperature, null: false, default: 1
      t.date :expected_close_date
      t.datetime :closed_at
      t.string :lost_reason
      t.integer :position, null: false, default: 0

      t.timestamps
    end

    add_index :crm_deals, [:account_id, :pipeline_id]
    add_index :crm_deals, [:account_id, :stage_id, :position]
    add_index :crm_deals, [:account_id, :assigned_user_id]
    add_index :crm_deals, [:account_id, :contact_id]
    add_index :crm_deals, [:account_id, :conversation_id]
    add_index :crm_deals, [:account_id, :status]
    add_index :crm_deals, [:account_id, :expected_close_date]

    create_table :crm_tasks do |t|
      t.references :account, null: false, foreign_key: true, index: true
      t.references :assigned_user, foreign_key: { to_table: :users }
      t.references :contact, foreign_key: true
      t.references :conversation, foreign_key: true
      t.references :deal, foreign_key: { to_table: :crm_deals }

      t.string :title, null: false
      t.text :description
      t.integer :task_type, null: false, default: 0
      t.integer :status, null: false, default: 0
      t.integer :priority, null: false, default: 1
      t.datetime :due_at
      t.datetime :completed_at
      t.datetime :cancelled_at

      t.timestamps
    end

    add_index :crm_tasks, [:account_id, :assigned_user_id, :status]
    add_index :crm_tasks, [:account_id, :due_at]
    add_index :crm_tasks, [:account_id, :deal_id]
    add_index :crm_tasks, [:account_id, :conversation_id]
    add_index :crm_tasks, [:account_id, :contact_id]
    add_index :crm_tasks, [:account_id, :task_type]

    create_table :crm_activities do |t|
      t.references :account, null: false, foreign_key: true, index: true
      t.references :deal, foreign_key: { to_table: :crm_deals }
      t.references :contact, foreign_key: true
      t.references :conversation, foreign_key: true
      t.references :actor, foreign_key: { to_table: :users }
      t.string :action, null: false
      t.jsonb :metadata, null: false, default: {}

      t.timestamps
    end

    add_index :crm_activities, [:account_id, :deal_id, :created_at]
    add_index :crm_activities, [:account_id, :contact_id, :created_at]
    add_index :crm_activities, [:account_id, :conversation_id, :created_at]
    add_index :crm_activities, [:account_id, :action]
    add_index :crm_activities, :metadata, using: :gin
  end
end
