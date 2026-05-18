<script setup>
import { ref, computed, watch } from 'vue';
import { useStore } from 'dashboard/composables/store';
import { useAlert } from 'dashboard/composables';
import { useI18n } from 'vue-i18n';
import {
  temperatureConfig,
  getCurrencySymbol,
  formatAmountForInput,
  formatDealAmount,
  maskAmountInput,
  parseAmountFromInput,
} from 'dashboard/composables/useCrmDealCardPresentation';
import Select from 'dashboard/components-next/select/Select.vue';
import Input from 'dashboard/components-next/input/Input.vue';
import Button from 'dashboard/components-next/button/Button.vue';

const props = defineProps({
  deal: { type: Object, required: true },
  field: {
    type: String,
    required: true,
    validator: value => ['amount', 'lead_temperature'].includes(value),
  },
  label: { type: String, required: true },
});

const store = useStore();
const { t } = useI18n();

const isEditing = ref(false);
const isSaving = ref(false);
const draftAmountDisplay = ref('');
const draftTemperature = ref('warm');

const currencyCode = computed(() => props.deal.currency || 'BRL');

const currencySymbol = computed(() => getCurrencySymbol(currencyCode.value));

const temperatureOptions = computed(() => [
  { value: 'cold', label: t('CRM_PIPELINE.DEAL.COLD') },
  { value: 'warm', label: t('CRM_PIPELINE.DEAL.WARM') },
  { value: 'hot', label: t('CRM_PIPELINE.DEAL.HOT') },
]);

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
  return formatDealAmount(props.deal.amount, currencyCode.value);
});

const syncDraftFromDeal = () => {
  if (props.field === 'amount') {
    draftAmountDisplay.value = formatAmountForInput(
      props.deal.amount,
      currencyCode.value
    );
  }
  if (props.field === 'lead_temperature') {
    draftTemperature.value = props.deal.lead_temperature || 'warm';
  }
};

watch(
  () => [props.deal?.id, props.deal?.amount, props.deal?.lead_temperature],
  () => {
    if (!isEditing.value) {
      syncDraftFromDeal();
    }
  },
  { immediate: true }
);

watch(
  () => props.deal?.id,
  () => {
    isEditing.value = false;
    syncDraftFromDeal();
  }
);

const startEdit = () => {
  syncDraftFromDeal();
  isEditing.value = true;
};

const cancelEdit = () => {
  syncDraftFromDeal();
  isEditing.value = false;
};

const applyAmountMask = rawValue => {
  return maskAmountInput(rawValue, currencyCode.value);
};

const onAmountInput = event => {
  const masked = applyAmountMask(event.target.value);
  if (event.target.value !== masked) {
    event.target.value = masked;
  }
  draftAmountDisplay.value = masked;
};

const onAmountKeydown = event => {
  if (event.ctrlKey || event.metaKey || event.altKey) return;

  const allowedKeys = [
    'Backspace',
    'Delete',
    'Tab',
    'ArrowLeft',
    'ArrowRight',
    'Home',
    'End',
  ];
  if (allowedKeys.includes(event.key)) return;

  if (/^\d$/.test(event.key)) return;

  event.preventDefault();
};

const onAmountPaste = event => {
  event.preventDefault();
  const pasted = event.clipboardData?.getData('text') || '';
  const { selectionStart, selectionEnd, value } = event.target;
  const nextValue = `${value.slice(0, selectionStart)}${pasted}${value.slice(selectionEnd)}`;
  const masked = applyAmountMask(nextValue);
  event.target.value = masked;
  draftAmountDisplay.value = masked;
};

const normalizeAmountDisplay = event => {
  const masked = applyAmountMask(
    event?.target?.value ?? draftAmountDisplay.value
  );
  if (event?.target && event.target.value !== masked) {
    event.target.value = masked;
  }
  draftAmountDisplay.value = masked;
};

const saveParams = () => {
  if (props.field === 'amount') {
    return {
      amount: parseAmountFromInput(
        draftAmountDisplay.value,
        currencyCode.value
      ),
      currency: currencyCode.value,
    };
  }
  return { lead_temperature: draftTemperature.value };
};

const save = async () => {
  isSaving.value = true;
  try {
    await store.dispatch('crmPipeline/updateDeal', {
      id: props.deal.id,
      params: saveParams(),
      pipelineId: props.deal.pipeline.id,
      refreshDeal: true,
    });
    isEditing.value = false;
    useAlert(t('CRM_PIPELINE.DEAL.SAVED'));
  } finally {
    isSaving.value = false;
  }
};
</script>

<template>
  <div class="rounded-2xl border border-n-weak bg-n-alpha-1 p-4">
    <div class="flex items-start justify-between gap-2">
      <p
        class="text-[11px] font-medium uppercase tracking-wide text-n-slate-11"
      >
        {{ label }}
      </p>
      <button
        v-if="!isEditing"
        type="button"
        class="inline-flex items-center gap-1 text-xs text-n-slate-11 transition-colors hover:text-n-slate-12 shrink-0"
        @click="startEdit"
      >
        <span class="i-lucide-pencil size-3.5" aria-hidden="true" />
        {{ $t('CRM_PIPELINE.TASKS.EDIT_ACTION') }}
      </button>
    </div>

    <template v-if="isEditing">
      <Input
        v-if="field === 'amount'"
        :model-value="draftAmountDisplay"
        type="text"
        inputmode="numeric"
        autocomplete="off"
        size="sm"
        class="mt-2 w-full [&>input]:!bg-n-surface-1 [&>input]:ltr:!pl-9 [&>input]:rtl:!pr-9"
        :placeholder="formatAmountForInput(0, currencyCode)"
        @input="onAmountInput"
        @keydown="onAmountKeydown"
        @paste="onAmountPaste"
        @blur="normalizeAmountDisplay"
      >
        <template #prefix>
          <span
            class="absolute top-1/2 -translate-y-1/2 text-sm font-medium text-n-slate-11 ltr:left-3 rtl:right-3"
          >
            {{ currencySymbol }}
          </span>
        </template>
      </Input>

      <Select
        v-else-if="field === 'lead_temperature'"
        v-model="draftTemperature"
        :options="temperatureOptions"
        full-width
        class="mt-2"
      />

      <div class="flex justify-end gap-2 mt-3">
        <Button
          faded
          slate
          sm
          type="button"
          :label="$t('CRM_PIPELINE.ACTIONS.CANCEL')"
          :disabled="isSaving"
          @click="cancelEdit"
        />
        <Button
          sm
          type="button"
          :label="$t('CRM_PIPELINE.ACTIONS.SAVE')"
          :is-loading="isSaving"
          @click="save"
        />
      </div>
    </template>

    <template v-else-if="field === 'amount'">
      <p class="mt-1 text-sm font-medium text-n-slate-12 break-words">
        {{ formattedAmount }}
      </p>
    </template>
    <template v-else-if="field === 'lead_temperature'">
      <span
        v-if="temperatureBadge"
        class="inline-flex mt-2 items-center gap-1 rounded-full px-2 py-1 text-xs font-semibold"
        :class="temperatureBadge.badgeClass"
      >
        <span
          class="size-3.5"
          :class="temperatureBadge.icon"
          aria-hidden="true"
        />
        {{ temperatureBadge.label }}
      </span>
      <p v-else class="mt-1 text-sm font-medium text-n-slate-12">—</p>
    </template>
  </div>
</template>
