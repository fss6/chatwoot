<script setup>
import { computed, toRef } from 'vue';
import { useI18n } from 'vue-i18n';
import { useCrmDealClosedState } from 'dashboard/composables/useCrmDealClosedState';
import CrmPipelineDealEditableMetric from './CrmPipelineDealEditableMetric.vue';

const props = defineProps({
  deal: { type: Object, required: true },
});

const { isReadOnly } = useCrmDealClosedState(toRef(props, 'deal'));

const { t } = useI18n();

const staticMetrics = computed(() => [
  {
    label: t('CRM_PIPELINE.DEAL.CONTACT'),
    value: props.deal.contact?.name || '—',
  },
]);
</script>

<template>
  <section class="grid grid-cols-2 gap-3 mb-5 md:grid-cols-4">
    <CrmPipelineDealEditableMetric
      :deal="deal"
      field="amount"
      :label="$t('CRM_PIPELINE.DEAL.AMOUNT')"
      :read-only="isReadOnly"
    />
    <CrmPipelineDealEditableMetric
      :deal="deal"
      field="lead_temperature"
      :label="$t('CRM_PIPELINE.DEAL.TEMPERATURE')"
      :read-only="isReadOnly"
    />
    <CrmPipelineDealEditableMetric
      :deal="deal"
      field="assigned_user"
      :label="$t('CRM_PIPELINE.DEAL.ASSIGNEE')"
      :read-only="isReadOnly"
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
