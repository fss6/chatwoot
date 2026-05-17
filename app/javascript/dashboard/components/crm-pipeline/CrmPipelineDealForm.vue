<script setup>
import { ref, watch, computed } from 'vue';
import { useI18n } from 'vue-i18n';
import CrmPipelineContactSelect from './CrmPipelineContactSelect.vue';
import CrmPipelineFormField from './CrmPipelineFormField.vue';
import CrmPipelineDealMetaRow from './CrmPipelineDealMetaRow.vue';
import CrmPipelineDealStageStepper from './CrmPipelineDealStageStepper.vue';
import Avatar from 'dashboard/components-next/avatar/Avatar.vue';

const props = defineProps({
  initialValues: { type: Object, default: () => ({}) },
  lockedContact: { type: Object, default: null },
  stages: { type: Array, default: () => [] },
  agents: { type: Array, default: () => [] },
  variant: {
    type: String,
    default: 'default',
    validator: v => ['default', 'crm', 'crm-edit'].includes(v),
  },
});

const emit = defineEmits(['submit']);

const { t } = useI18n();

const form = ref({
  title: '',
  amount: '',
  currency: 'BRL',
  stage_id: null,
  contact_id: null,
  assigned_user_id: '',
  source: '',
  lead_temperature: 'warm',
  description: '',
  expected_close_date: '',
});

const stageOptions = computed(() =>
  props.stages.map(stage => ({ value: stage.id, label: stage.name }))
);

const agentOptions = computed(() => [
  { value: '', label: t('CRM_PIPELINE.DEAL.UNASSIGNED') },
  ...props.agents.map(agent => ({ value: agent.id, label: agent.name })),
]);

const temperatureOptions = computed(() => [
  { value: 'cold', label: t('CRM_PIPELINE.DEAL.COLD') },
  { value: 'warm', label: t('CRM_PIPELINE.DEAL.WARM') },
  { value: 'hot', label: t('CRM_PIPELINE.DEAL.HOT') },
]);

const selectedAssignee = computed(() =>
  props.agents.find(a => a.id === form.value.assigned_user_id)
);

watch(
  () => props.initialValues,
  values => {
    if (!values || !Object.keys(values).length) return;

    form.value = {
      ...form.value,
      ...values,
      assigned_user_id:
        values.assigned_user_id || values.assigned_user?.id || '',
      contact_id: values.contact_id || values.contact?.id || null,
      description: values.description || '',
      expected_close_date: values.expected_close_date || '',
      amount: values.amount ?? '',
    };
    if (values.stage_id) form.value.stage_id = values.stage_id;
    else if (props.stages.length) form.value.stage_id = props.stages[0].id;
  },
  { immediate: true, deep: true }
);

const submit = () => {
  const contactId = props.lockedContact?.id || form.value.contact_id;
  if (!contactId) return;

  emit('submit', {
    ...form.value,
    contact_id: contactId,
    assigned_user_id: form.value.assigned_user_id || null,
    amount: form.value.amount ? Number(form.value.amount) : null,
    expected_close_date: form.value.expected_close_date || null,
  });
};

defineExpose({ submit, form });
</script>

<template>
  <form class="flex flex-col items-start w-full gap-0" @submit.prevent="submit">
    <template v-if="variant === 'crm' || variant === 'crm-edit'">
      <div
        v-if="variant === 'crm'"
        class="flex flex-col gap-3 w-full pb-4 mb-5 border-b border-n-weak lg:flex-row lg:items-center lg:justify-between"
      >
        <slot name="header-actions" />
        <CrmPipelineDealStageStepper
          v-model="form.stage_id"
          :stages="stages"
          class="w-full lg:max-w-[55%]"
        />
      </div>

      <input
        v-if="variant === 'crm'"
        v-model="form.title"
        type="text"
        required
        class="w-full mb-5 text-2xl font-semibold text-n-slate-12 bg-transparent border-0 p-0 focus:outline-none focus:ring-0 placeholder:text-n-slate-10"
        :placeholder="$t('CRM_PIPELINE.DEAL.TITLE')"
      />

      <div v-if="variant === 'crm-edit'" class="w-full mb-4">
        <CrmPipelineFormField :label="$t('CRM_PIPELINE.DEAL.TITLE')">
          <input v-model="form.title" type="text" required />
        </CrmPipelineFormField>
      </div>

      <div v-if="variant === 'crm-edit'" class="w-full mb-4">
        <CrmPipelineFormField :label="$t('CRM_PIPELINE.DEAL.STAGE')">
          <select v-model="form.stage_id">
            <option
              v-for="option in stageOptions"
              :key="option.value"
              :value="option.value"
            >
              {{ option.label }}
            </option>
          </select>
        </CrmPipelineFormField>
      </div>

      <div class="w-full rounded-lg border border-n-weak bg-n-alpha-1 px-4">
        <CrmPipelineDealMetaRow :label="$t('CRM_PIPELINE.DEAL.CONTACT')">
          <CrmPipelineContactSelect
            v-if="lockedContact"
            bare
            :model-value="lockedContact.id"
            :locked-contact="lockedContact"
            disabled
          />
          <CrmPipelineContactSelect v-else v-model="form.contact_id" bare />
        </CrmPipelineDealMetaRow>

        <CrmPipelineDealMetaRow :label="$t('CRM_PIPELINE.DEAL.ASSIGNEE')">
          <div class="flex items-center gap-2 min-w-0">
            <Avatar
              v-if="selectedAssignee"
              :name="selectedAssignee.name"
              :size="24"
              rounded-full
              class="shrink-0"
            />
            <span
              v-else
              class="flex size-6 shrink-0 items-center justify-center rounded-full bg-n-alpha-2"
            >
              <span class="i-lucide-user-round size-3.5 text-n-slate-10" />
            </span>
            <select
              v-model="form.assigned_user_id"
              class="flex-1 min-w-0 text-sm"
            >
              <option
                v-for="option in agentOptions"
                :key="option.value"
                :value="option.value"
              >
                {{ option.label }}
              </option>
            </select>
          </div>
        </CrmPipelineDealMetaRow>

        <CrmPipelineDealMetaRow :label="$t('CRM_PIPELINE.DEAL.AMOUNT')">
          <div class="flex items-center gap-2">
            <input
              v-model="form.amount"
              type="number"
              min="0"
              step="0.01"
              class="w-32 text-sm"
              :placeholder="$t('CRM_PIPELINE.DEAL.AMOUNT_PLACEHOLDER')"
            />
            <span class="text-sm text-n-slate-11">{{ form.currency }}</span>
          </div>
        </CrmPipelineDealMetaRow>

        <CrmPipelineDealMetaRow :label="$t('CRM_PIPELINE.DEAL.TEMPERATURE')">
          <select
            v-model="form.lead_temperature"
            class="w-full max-w-xs text-sm"
          >
            <option
              v-for="option in temperatureOptions"
              :key="option.value"
              :value="option.value"
            >
              {{ option.label }}
            </option>
          </select>
        </CrmPipelineDealMetaRow>

        <CrmPipelineDealMetaRow :label="$t('CRM_PIPELINE.DEAL.SOURCE')">
          <input
            v-model="form.source"
            type="text"
            class="w-full max-w-md text-sm"
            :placeholder="$t('CRM_PIPELINE.DEAL.SOURCE_PLACEHOLDER')"
          />
        </CrmPipelineDealMetaRow>

        <CrmPipelineDealMetaRow :label="$t('CRM_PIPELINE.DEAL.EXPECTED_CLOSE')">
          <input
            v-model="form.expected_close_date"
            type="date"
            class="w-full max-w-xs text-sm"
          />
        </CrmPipelineDealMetaRow>

        <CrmPipelineDealMetaRow
          :label="$t('CRM_PIPELINE.DEAL.DESCRIPTION')"
          align-top
        >
          <textarea
            v-model="form.description"
            rows="3"
            class="w-full text-sm rounded-lg border border-n-weak bg-n-solid-1 px-3 py-2 resize-y min-h-[4.5rem]"
            :placeholder="$t('CRM_PIPELINE.DEAL.DESCRIPTION_PLACEHOLDER')"
          />
        </CrmPipelineDealMetaRow>
      </div>
    </template>

    <template v-else-if="variant === 'default'">
      <CrmPipelineContactSelect
        v-if="lockedContact"
        :model-value="lockedContact.id"
        :locked-contact="lockedContact"
        disabled
      />
      <CrmPipelineContactSelect v-else v-model="form.contact_id" />

      <CrmPipelineFormField :label="$t('CRM_PIPELINE.DEAL.TITLE')">
        <input v-model="form.title" type="text" required />
      </CrmPipelineFormField>

      <CrmPipelineFormField :label="$t('CRM_PIPELINE.DEAL.AMOUNT')">
        <input v-model="form.amount" type="number" min="0" step="0.01" />
      </CrmPipelineFormField>

      <CrmPipelineFormField :label="$t('CRM_PIPELINE.DEAL.STAGE')">
        <select v-model="form.stage_id">
          <option
            v-for="option in stageOptions"
            :key="option.value"
            :value="option.value"
          >
            {{ option.label }}
          </option>
        </select>
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

      <CrmPipelineFormField :label="$t('CRM_PIPELINE.DEAL.TEMPERATURE')">
        <select v-model="form.lead_temperature">
          <option
            v-for="option in temperatureOptions"
            :key="option.value"
            :value="option.value"
          >
            {{ option.label }}
          </option>
        </select>
      </CrmPipelineFormField>

      <CrmPipelineFormField :label="$t('CRM_PIPELINE.DEAL.DESCRIPTION')">
        <textarea v-model="form.description" rows="3" />
      </CrmPipelineFormField>
    </template>

    <slot name="actions" />
  </form>
</template>
