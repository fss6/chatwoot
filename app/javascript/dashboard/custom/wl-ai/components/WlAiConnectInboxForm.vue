<script setup>
import { reactive, computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { useVuelidate } from '@vuelidate/core';
import { required } from '@vuelidate/validators';
import { useMapGetter } from 'dashboard/composables/store';

import Button from 'dashboard/components-next/button/Button.vue';
import ComboBox from 'dashboard/components-next/combobox/ComboBox.vue';

const props = defineProps({
  assistantId: {
    type: Number,
    required: true,
  },
  occupiedInboxIds: {
    type: Array,
    default: () => [],
  },
  isSubmitting: {
    type: Boolean,
    default: false,
  },
});

const emit = defineEmits(['submit', 'cancel']);

const { t } = useI18n();

const accountInboxes = useMapGetter('inboxes/getInboxes');

const initialState = {
  inboxId: null,
};

const state = reactive({ ...initialState });

const validationRules = {
  inboxId: { required },
};

const occupiedSet = computed(
  () => new Set((props.occupiedInboxIds || []).map(Number))
);

const inboxList = computed(() =>
  (accountInboxes.value || [])
    .filter(inbox => !occupiedSet.value.has(inbox.id))
    .map(inbox => ({
      value: inbox.id,
      label: inbox.name,
    }))
);

const v$ = useVuelidate(validationRules, state);

const getErrorMessage = (field, errorKey) => {
  return v$.value[field].$error
    ? t(`WL_AI.INBOXES.FORM.${errorKey}.ERROR`)
    : '';
};

const formErrors = computed(() => ({
  inboxId: getErrorMessage('inboxId', 'INBOX'),
}));

const handleCancel = () => emit('cancel');

const handleSubmit = async () => {
  const isFormValid = await v$.value.$validate();
  if (!isFormValid) {
    return;
  }

  emit('submit', {
    inboxId: state.inboxId,
    assistantId: props.assistantId,
  });
};
</script>

<template>
  <form class="flex flex-col gap-4" @submit.prevent="handleSubmit">
    <div class="flex flex-col gap-1">
      <label
        for="wl-ai-inbox"
        class="mb-0.5 text-sm font-medium text-n-slate-12"
      >
        {{ t('WL_AI.INBOXES.FORM.INBOX.LABEL') }}
      </label>
      <ComboBox
        id="wl-ai-inbox"
        v-model="state.inboxId"
        :options="inboxList"
        :has-error="!!formErrors.inboxId"
        :placeholder="t('WL_AI.INBOXES.FORM.INBOX.PLACEHOLDER')"
        class="[&>div>button]:bg-n-alpha-black2 [&>div>button:not(.focused)]:dark:outline-n-weak [&>div>button:not(.focused)]:hover:!outline-n-slate-6"
        :message="formErrors.inboxId"
      />
    </div>

    <div class="flex items-center justify-between w-full gap-3">
      <Button
        type="button"
        variant="faded"
        color="slate"
        :label="t('WL_AI.INBOXES.FORM.CANCEL')"
        class="w-full bg-n-alpha-2 text-n-blue-11 hover:bg-n-alpha-3"
        @click="handleCancel"
      />
      <Button
        type="submit"
        :label="t('WL_AI.INBOXES.FORM.SUBMIT')"
        class="w-full"
        :is-loading="isSubmitting"
        :disabled="isSubmitting"
      />
    </div>
  </form>
</template>
