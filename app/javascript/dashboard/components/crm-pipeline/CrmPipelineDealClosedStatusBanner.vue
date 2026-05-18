<script setup>
import { computed, toRef } from 'vue';
import { useI18n } from 'vue-i18n';
import {
  formatDealClosedAtLabel,
  useCrmDealClosedState,
} from 'dashboard/composables/useCrmDealClosedState';

const props = defineProps({
  deal: { type: Object, required: true },
});

const { t } = useI18n();
const { isWon, isLost } = useCrmDealClosedState(toRef(props, 'deal'));

const closedAtLabel = computed(() =>
  formatDealClosedAtLabel(props.deal.closed_at || props.deal.closedAt)
);

const lostReasonText = computed(() => {
  const reason = (props.deal.lost_reason || props.deal.lostReason)?.trim();
  return reason || t('CRM_PIPELINE.DEAL.LOST_REASON_NOT_PROVIDED');
});
</script>

<template>
  <div
    v-if="isLost"
    class="rounded-2xl border border-n-ruby-8 bg-n-ruby-3 px-4 py-3"
    role="status"
  >
    <div class="flex flex-wrap items-start gap-2">
      <span
        class="i-lucide-circle-x size-4 shrink-0 text-n-ruby-11 mt-0.5"
        aria-hidden="true"
      />
      <div class="min-w-0 flex-1 space-y-1">
        <p class="text-sm font-semibold text-n-ruby-11">
          {{ $t('CRM_PIPELINE.DEAL.STATUS_LOST') }}
          <span v-if="closedAtLabel" class="font-normal text-n-ruby-11/80">
            <span class="text-n-ruby-11/80" aria-hidden="true">{{
              $t('CRM_PIPELINE.TASKS.META_SEPARATOR')
            }}</span>
            {{ closedAtLabel }}
          </span>
        </p>
        <p
          class="text-sm text-n-ruby-11 leading-relaxed whitespace-pre-wrap break-words"
        >
          <span class="font-medium">
            {{ $t('CRM_PIPELINE.DEAL.LOST_REASON_COLON') }}
          </span>
          {{ lostReasonText }}
        </p>
        <p class="text-xs text-n-ruby-11/80">
          {{ $t('CRM_PIPELINE.DEAL.CLOSED_LOST_READONLY_HINT') }}
        </p>
      </div>
    </div>
  </div>

  <div
    v-else-if="isWon"
    class="rounded-2xl border border-n-teal-8 bg-n-teal-3 px-4 py-3"
    role="status"
  >
    <div class="flex flex-wrap items-start gap-2">
      <span
        class="i-lucide-circle-check size-4 shrink-0 text-n-teal-11 mt-0.5"
        aria-hidden="true"
      />
      <div class="min-w-0 flex-1 space-y-1">
        <p class="text-sm font-semibold text-n-teal-11">
          {{ $t('CRM_PIPELINE.DEAL.STATUS_WON') }}
          <span v-if="closedAtLabel" class="font-normal text-n-teal-11/80">
            <span class="text-n-teal-11/80" aria-hidden="true">{{
              $t('CRM_PIPELINE.TASKS.META_SEPARATOR')
            }}</span>
            {{ closedAtLabel }}
          </span>
        </p>
        <p class="text-xs text-n-teal-11/80">
          {{ $t('CRM_PIPELINE.DEAL.CLOSED_READONLY_HINT') }}
        </p>
      </div>
    </div>
  </div>
</template>
