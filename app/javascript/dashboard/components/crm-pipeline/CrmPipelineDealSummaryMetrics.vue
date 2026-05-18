<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import CrmPipelineDealEditableMetric from './CrmPipelineDealEditableMetric.vue';

const props = defineProps({
  deal: { type: Object, required: true },
});

const { t } = useI18n();

const staticMetrics = computed(() => [
  {
    label: t('CRM_PIPELINE.DEAL.CONTACT'),
    value: props.deal.contact?.name || '—',
  },
  {
    label: t('CRM_PIPELINE.DEAL.ASSIGNEE'),
    value: props.deal.assigned_user?.name || t('CRM_PIPELINE.DEAL.UNASSIGNED'),
  },
]);
</script>

<template>
  <section class="grid grid-cols-2 gap-3 mb-5 md:grid-cols-4">
    <CrmPipelineDealEditableMetric
      :deal="deal"
      field="amount"
      :label="$t('CRM_PIPELINE.DEAL.AMOUNT')"
    />
    <CrmPipelineDealEditableMetric
      :deal="deal"
      field="lead_temperature"
      :label="$t('CRM_PIPELINE.DEAL.TEMPERATURE')"
    />
    <div
      v-for="metric in staticMetrics"
      :key="metric.label"
      class="rounded-2xl border border-n-weak bg-n-alpha-1 p-4"
    >
      <p
        class="text-[11px] font-medium uppercase tracking-wide text-n-slate-11"
      >
        {{ metric.label }}
      </p>
      <p class="mt-1 text-sm font-medium text-n-slate-12 truncate">
        {{ metric.value }}
      </p>
    </div>
  </section>
</template>
