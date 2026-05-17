<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import CrmPipelineDealEditableMetric from './CrmPipelineDealEditableMetric.vue';

const props = defineProps({
  deal: { type: Object, required: true },
});

const { t } = useI18n();

const formattedCloseDate = computed(() => {
  if (!props.deal.expected_close_date) {
    return t('CRM_PIPELINE.DEAL.NO_EXPECTED_CLOSE');
  }
  return new Date(props.deal.expected_close_date).toLocaleDateString(
    undefined,
    { day: 'numeric', month: 'short', year: 'numeric' }
  );
});

const staticMetrics = computed(() => [
  {
    label: t('CRM_PIPELINE.DEAL.SOURCE'),
    value: props.deal.source || '—',
  },
  {
    label: t('CRM_PIPELINE.DEAL.EXPECTED_CLOSE'),
    value: formattedCloseDate.value,
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
