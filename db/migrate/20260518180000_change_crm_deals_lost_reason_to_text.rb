class ChangeCrmDealsLostReasonToText < ActiveRecord::Migration[7.1]
  def up
    change_column :crm_deals, :lost_reason, :text
  end

  def down
    change_column :crm_deals, :lost_reason, :string
  end
end
