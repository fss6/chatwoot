<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { temperatureConfig } from 'dashboard/composables/useCrmDealCardPresentation';

const props = defineProps({
  deal: { type: Object, required: true },
});

const { t } = useI18n();

const temperatureBadge = computed(() => {
  const key = props.deal.lead_temperature;
  const config = temperatureConfig[key];
  if (!config) return null;
  return {
    label: t(`CRM_PIPELINE.DEAL.${config.labelKey}`),
    badgeClass: config.badgeClass,
    icon: config.icon,
  };
});

const formattedAmount = computed(() => {
  if (!props.deal.amount) {
    return t('CRM_PIPELINE.DEAL.AMOUNT_NOT_INFORMED');
  }
  return new Intl.NumberFormat(undefined, {
    style: 'currency',
    currency: props.deal.currency || 'BRL',
    minimumFractionDigits: 2,
    maximumFractionDigits: 2,
  }).format(props.deal.amount);
});

const formattedCloseDate = computed(() => {
  if (!props.deal.expected_close_date) {
    return t('CRM_PIPELINE.DEAL.NO_EXPECTED_CLOSE');
  }
  return new Date(props.deal.expected_close_date).toLocaleDateString(
    undefined,
    { day: 'numeric', month: 'short', year: 'numeric' }
  );
});

const metrics = computed(() => [
  {
    label: t('CRM_PIPELINE.DEAL.AMOUNT'),
    value: formattedAmount.value,
    isBadge: false,
  },
  {
    label: t('CRM_PIPELINE.DEAL.TEMPERATURE'),
    value: temperatureBadge.value?.label || '—',
    isBadge: Boolean(temperatureBadge.value),
    badgeClass: temperatureBadge.value?.badgeClass,
    icon: temperatureBadge.value?.icon,
  },
  {
    label: t('CRM_PIPELINE.DEAL.SOURCE'),
    value: props.deal.source || '—',
    isBadge: false,
  },
  {
    label: t('CRM_PIPELINE.DEAL.EXPECTED_CLOSE'),
    value: formattedCloseDate.value,
    isBadge: false,
  },
]);
</script>

<template>
  <section class="grid grid-cols-2 gap-3 mb-5 md:grid-cols-4">
    <div
      v-for="metric in metrics"
      :key="metric.label"
      class="rounded-2xl border border-n-weak bg-n-alpha-1 p-4"
    >
      <p
        class="text-[11px] font-medium uppercase tracking-wide text-n-slate-11"
      >
        {{ metric.label }}
      </p>
      <span
        v-if="metric.isBadge"
        class="inline-flex mt-2 items-center gap-1 rounded-full px-2 py-1 text-xs font-semibold"
        :class="metric.badgeClass"
      >
        <span class="size-3.5" :class="metric.icon" aria-hidden="true" />
        {{ metric.value }}
      </span>
      <p v-else class="mt-1 text-sm font-medium text-n-slate-12 truncate">
        {{ metric.value }}
      </p>
    </div>
  </section>
</template>
