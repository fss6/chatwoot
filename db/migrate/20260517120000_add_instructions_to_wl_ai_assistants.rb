# frozen_string_literal: true

class AddInstructionsToWlAiAssistants < ActiveRecord::Migration[7.1]
  def up
    add_column :wl_ai_assistants, :instructions, :text

    say_with_time 'copy account-level WL AI instructions into assistants when empty' do
      WlAiAccountCredential.reset_column_information
      WlAiAssistant.reset_column_information

      WlAiAccountCredential.find_each do |cred|
        text = cred.system_instructions.to_s.strip
        next if text.blank?

        WlAiAssistant.where(account_id: cred.account_id).find_each do |asst|
          next if asst.instructions.present?

          asst.update_columns(instructions: text)
        end
      end
    end
  end

  def down
    remove_column :wl_ai_assistants, :instructions
  end
end
