<script setup>
import { ref, computed, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import DateTimePicker from 'dashboard/components/ui/DateTimePicker.vue';
import CrmPipelineContactSelect from './CrmPipelineContactSelect.vue';
import CrmPipelineFormField from './CrmPipelineFormField.vue';

const props = defineProps({
  lockedDeal: { type: Object, default: null },
  lockedContact: { type: Object, default: null },
  lockedConversationId: { type: [Number, String], default: null },
  agents: { type: Array, default: () => [] },
  deals: { type: Array, default: () => [] },
  initialTask: { type: Object, default: null },
});

const emit = defineEmits(['submit']);

const { t } = useI18n();

const taskTypes = [
  'follow_up',
  'call',
  'send_proposal',
  'send_contract',
  'payment_check',
  'meeting',
  'other',
];

const priorities = ['low', 'normal', 'high', 'urgent'];

const dueAt = ref(null);

const form = ref({
  title: '',
  description: '',
  task_type: 'follow_up',
  priority: 'normal',
  assigned_user_id: '',
  deal_id: '',
  contact_id: null,
  conversation_id: null,
});

const onDueAtChange = date => {
  dueAt.value = date;
};

const showDealSelect = computed(
  () => props.deals.length > 0 && !props.lockedDeal
);

const showContactSelect = computed(
  () => !props.lockedDeal && !props.lockedContact
);

const lockedDealLabel = computed(() => props.lockedDeal?.title || '');

const dealOptions = computed(() => [
  { value: '', label: t('CRM_PIPELINE.TASKS.NO_DEAL') },
  ...props.deals.map(deal => ({ value: deal.id, label: deal.title })),
]);

const taskTypeOptions = computed(() =>
  taskTypes.map(type => ({
    value: type,
    label: t(`CRM_PIPELINE.TASKS.TYPES.${type}`),
  }))
);

const priorityOptions = computed(() =>
  priorities.map(priority => ({
    value: priority,
    label: t(`CRM_PIPELINE.TASKS.PRIORITIES.${priority}`),
  }))
);

const agentOptions = computed(() => [
  { value: '', label: t('CRM_PIPELINE.DEAL.UNASSIGNED') },
  ...props.agents.map(agent => ({ value: agent.id, label: agent.name })),
]);

const applyLockedContext = () => {
  form.value.deal_id = props.lockedDeal?.id ? String(props.lockedDeal.id) : '';
  form.value.contact_id =
    props.lockedContact?.id ?? props.lockedDeal?.contact?.id ?? null;
  form.value.conversation_id =
    props.lockedConversationId ?? props.lockedDeal?.conversation?.id ?? null;
  form.value.assigned_user_id = props.lockedDeal?.assigned_user?.id
    ? String(props.lockedDeal.assigned_user.id)
    : '';
};

watch(
  () => [props.lockedDeal, props.lockedContact, props.lockedConversationId],
  applyLockedContext,
  { immediate: true }
);

watch(
  () => form.value.deal_id,
  dealId => {
    if (!dealId) {
      form.value.conversation_id = props.lockedConversationId ?? null;
      return;
    }

    const deal = props.deals.find(d => String(d.id) === String(dealId));
    if (deal?.contact?.id) {
      form.value.contact_id = deal.contact.id;
    }
    if (deal?.conversation?.id) {
      form.value.conversation_id = deal.conversation.id;
    }
  }
);

const submit = () => {
  const title = form.value.title.trim();
  if (!title) return;

  const dealId = props.lockedDeal?.id || form.value.deal_id || null;
  const contactId =
    props.lockedContact?.id ??
    props.lockedDeal?.contact?.id ??
    form.value.contact_id;
  const conversationId =
    props.lockedConversationId ??
    props.lockedDeal?.conversation?.id ??
    form.value.conversation_id;

  if (!dealId && !contactId && !conversationId) return;

  emit('submit', {
    title,
    description: form.value.description?.trim() || '',
    task_type: form.value.task_type,
    priority: form.value.priority,
    due_at: dueAt.value ? dueAt.value.toISOString() : null,
    assigned_user_id: form.value.assigned_user_id || null,
    deal_id: dealId || null,
    contact_id: contactId || null,
    conversation_id: conversationId || null,
  });
};

const populateFromTask = task => {
  if (!task) return;

  form.value = {
    title: task.title || '',
    description: task.description || '',
    task_type: task.task_type || 'follow_up',
    priority: task.priority || 'normal',
    assigned_user_id: task.assigned_user?.id
      ? String(task.assigned_user.id)
      : '',
    deal_id: task.deal_id ? String(task.deal_id) : '',
    contact_id: task.contact_id ?? null,
    conversation_id: task.conversation_id ?? null,
  };
  dueAt.value = task.due_at ? new Date(task.due_at) : null;
};

const reset = () => {
  form.value = {
    title: '',
    description: '',
    task_type: 'follow_up',
    priority: 'normal',
    assigned_user_id: '',
    deal_id: '',
    contact_id: null,
    conversation_id: null,
  };
  dueAt.value = null;
  applyLockedContext();
};

watch(
  () => props.initialTask,
  task => {
    if (task) {
      populateFromTask(task);
    }
  },
  { immediate: true }
);

defineExpose({ reset, populateFromTask });
</script>

<template>
  <form class="flex flex-col items-start w-full gap-0" @submit.prevent="submit">
    <CrmPipelineFormField
      v-if="lockedDeal"
      :label="$t('CRM_PIPELINE.TASKS.LINK_DEAL')"
    >
      <p class="text-sm text-n-slate-11 mb-0">{{ lockedDealLabel }}</p>
    </CrmPipelineFormField>

    <CrmPipelineFormField
      v-else-if="showDealSelect"
      :label="$t('CRM_PIPELINE.TASKS.LINK_DEAL')"
    >
      <select v-model="form.deal_id">
        <option
          v-for="option in dealOptions"
          :key="option.value"
          :value="option.value"
        >
          {{ option.label }}
        </option>
      </select>
    </CrmPipelineFormField>

    <CrmPipelineContactSelect
      v-if="lockedContact"
      :model-value="lockedContact.id"
      :locked-contact="lockedContact"
      disabled
    />
    <CrmPipelineContactSelect
      v-else-if="showContactSelect"
      v-model="form.contact_id"
    />

    <CrmPipelineFormField :label="$t('CRM_PIPELINE.TASKS.TITLE_LABEL')">
      <input v-model="form.title" type="text" required />
    </CrmPipelineFormField>

    <CrmPipelineFormField :label="$t('CRM_PIPELINE.TASKS.DESCRIPTION')">
      <textarea v-model="form.description" rows="2" />
    </CrmPipelineFormField>

    <CrmPipelineFormField :label="$t('CRM_PIPELINE.TASKS.TYPE')">
      <select v-model="form.task_type">
        <option
          v-for="option in taskTypeOptions"
          :key="option.value"
          :value="option.value"
        >
          {{ option.label }}
        </option>
      </select>
    </CrmPipelineFormField>

    <CrmPipelineFormField :label="$t('CRM_PIPELINE.TASKS.PRIORITY')">
      <select v-model="form.priority">
        <option
          v-for="option in priorityOptions"
          :key="option.value"
          :value="option.value"
        >
          {{ option.label }}
        </option>
      </select>
    </CrmPipelineFormField>

    <CrmPipelineFormField :label="$t('CRM_PIPELINE.TASKS.DUE_AT')">
      <DateTimePicker
        :value="dueAt"
        :placeholder="$t('CRM_PIPELINE.TASKS.DUE_AT_PLACEHOLDER')"
        :confirm-text="$t('DATE_PICKER.APPLY_BUTTON')"
        @change="onDueAtChange"
      />
    </CrmPipelineFormField>

    <CrmPipelineFormField :label="$t('CRM_PIPELINE.DEAL.ASSIGNEE')">
      <select v-model="form.assigned_user_id">
        <option
          v-for="option in agentOptions"
          :key="option.value"
          :value="option.value"
        >
          {{ option.label }}
        </option>
      </select>
    </CrmPipelineFormField>

    <p
      v-if="!lockedDeal && !lockedContact && !form.deal_id && !form.contact_id"
      class="text-xs text-n-slate-11 w-full mb-2"
    >
      {{ $t('CRM_PIPELINE.TASKS.CONTEXT_REQUIRED') }}
    </p>

    <slot name="actions" />
  </form>
</template>
