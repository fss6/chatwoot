<script setup>
import { ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';

import Dialog from 'dashboard/components-next/dialog/Dialog.vue';
import WlAiConnectInboxForm from './WlAiConnectInboxForm.vue';
import wlAiInboxes from 'dashboard/api/wlAi/inboxes';

defineProps({
  assistantId: {
    type: Number,
    required: true,
  },
  occupiedInboxIds: {
    type: Array,
    default: () => [],
  },
});

const emit = defineEmits(['close', 'connected']);

const { t } = useI18n();

const dialogRef = ref(null);
const isSubmitting = ref(false);

const i18nKey = 'WL_AI.INBOXES.CREATE';

const handleSubmit = async payload => {
  isSubmitting.value = true;
  try {
    await wlAiInboxes.create(payload);
    useAlert(t(`${i18nKey}.SUCCESS_MESSAGE`));
    dialogRef.value?.close();
    emit('connected');
  } catch (error) {
    const errorMessage =
      error?.response?.data?.error ||
      error?.message ||
      t(`${i18nKey}.ERROR_MESSAGE`);
    useAlert(errorMessage);
  } finally {
    isSubmitting.value = false;
  }
};

const handleClose = () => {
  emit('close');
};

const handleCancel = () => {
  dialogRef.value?.close();
};

defineExpose({
  dialogRef,
  open: () => dialogRef.value?.open(),
});
</script>

<template>
  <Dialog
    ref="dialogRef"
    type="create"
    :title="$t(`${i18nKey}.TITLE`)"
    :description="$t('WL_AI.INBOXES.FORM_DESCRIPTION')"
    :show-cancel-button="false"
    :show-confirm-button="false"
    @close="handleClose"
  >
    <WlAiConnectInboxForm
      :assistant-id="assistantId"
      :occupied-inbox-ids="occupiedInboxIds"
      :is-submitting="isSubmitting"
      @submit="handleSubmit"
      @cancel="handleCancel"
    />
    <template #footer />
  </Dialog>
</template>
