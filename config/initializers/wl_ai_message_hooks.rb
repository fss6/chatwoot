# frozen_string_literal: true

# Fork: wires WL AI auto-reply and message/inbox behaviour without editing
# app/services/message_templates/hook_execution_service.rb or Enterprise equivalents.
Rails.application.config.to_prepare do
  hook = MessageTemplates::HookExecutionService
  hook_mod = WlAi::MessageTemplates::HookExtension
  hook.prepend(hook_mod) unless hook.ancestors.include?(hook_mod)

  msg = Message
  msg_ext = WlAi::MessageExtension
  msg.prepend(msg_ext) unless msg.ancestors.include?(msg_ext)

  inbox = Inbox
  inbox_ext = WlAi::InboxActiveBotExtension
  inbox.prepend(inbox_ext) unless inbox.ancestors.include?(inbox_ext)
end
