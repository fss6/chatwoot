# frozen_string_literal: true

class WlBotFlow < ApplicationRecord
  belongs_to :account
  belongs_to :inbox, optional: true
  belongs_to :agent_bot, optional: true

  has_many :wl_bot_sessions, dependent: :destroy_async
  has_many :wl_bot_execution_logs, through: :wl_bot_sessions

  enum status: { draft: 0, published: 1, paused: 2, archived: 3 }

  validates :name, presence: true
  validates :draft_json, presence: true

  scope :ordered, -> { order(updated_at: :desc) }

  def publish!
    validate_inbox_exclusivity!
    validate_publishable!

    transaction do
      increment!(:published_version)
      update!(
        published_json: draft_json,
        status: :published,
        published_at: Time.current
      )
      ensure_agent_bot!
      attach_agent_bot_to_inbox!
    end
  end

  def validate_publishable!
    WlBotFlows::Validator.new(draft_json, publish: true).validate!
  end

  def validate_inbox_exclusivity!
    return if inbox.blank?

    if inbox.respond_to?(:wl_ai_assistant) && inbox.wl_ai_assistant.present?
      raise WlBotFlows::PublishError, I18n.t('wl_bot_flows.errors.wl_ai_assistant_present')
    end

    if inbox.respond_to?(:captain_active?) && inbox.captain_active?
      raise WlBotFlows::PublishError, I18n.t('wl_bot_flows.errors.captain_active')
    end

    if inbox.hooks.where(app_id: 'dialogflow', status: :enabled).exists?
      raise WlBotFlows::PublishError, I18n.t('wl_bot_flows.errors.dialogflow_active')
    end
  end

  def ensure_agent_bot!
    bot = agent_bot || account.agent_bots.create!(
      name: "WL Bot Flow - #{name}",
      description: 'Managed by WL Bot Flows',
      bot_type: :webhook,
      bot_config: bot_config_payload
    )

    bot.update!(
      name: "WL Bot Flow - #{name}",
      outgoing_url: nil,
      bot_config: bot_config_payload
    )

    update!(agent_bot: bot) if agent_bot_id.blank?
  end

  def attach_agent_bot_to_inbox!
    return if inbox.blank? || agent_bot.blank?

    record = inbox.agent_bot_inbox || AgentBotInbox.new(inbox: inbox)
    record.agent_bot = agent_bot
    record.status = :active
    record.save!
  end

  def as_api_json
    {
      id: id,
      name: name,
      status: status,
      inbox_id: inbox_id,
      agent_bot_id: agent_bot_id,
      draft_json: draft_json,
      published_json: published_json,
      published_version: published_version,
      published_at: published_at,
      created_at: created_at,
      updated_at: updated_at
    }
  end

  private

  def bot_config_payload
    {
      'managed_by' => 'wl_bot_flows',
      'wl_bot_flow_id' => id,
      'published_version' => published_version
    }
  end
end
