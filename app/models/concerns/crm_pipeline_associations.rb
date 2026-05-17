module CrmPipelineAssociations
  extend ActiveSupport::Concern

  included do
    case base_class.name
    when 'Account'
      has_many :crm_pipelines, class_name: 'Crm::Pipeline', dependent: :destroy_async
      has_many :crm_deals, class_name: 'Crm::Deal', dependent: :destroy_async
      has_many :crm_tasks, class_name: 'Crm::Task', dependent: :destroy_async
      has_many :crm_activities, class_name: 'Crm::Activity', dependent: :destroy_async
    when 'Contact'
      has_many :crm_deals, class_name: 'Crm::Deal', dependent: :nullify
      has_many :crm_tasks, class_name: 'Crm::Task', dependent: :nullify
    when 'Conversation'
      has_many :crm_deals, class_name: 'Crm::Deal', dependent: :nullify
      has_many :crm_tasks, class_name: 'Crm::Task', dependent: :nullify
    end
  end
end
