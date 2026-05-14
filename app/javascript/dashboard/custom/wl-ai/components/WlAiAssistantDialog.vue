<script setup>
import { ref, watch, computed, defineOptions } from 'vue';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import wlAiAssistants from 'dashboard/api/wlAi/assistants';

import Dialog from 'dashboard/components-next/dialog/Dialog.vue';
import Input from 'dashboard/components-next/input/Input.vue';
import TextArea from 'dashboard/components-next/textarea/TextArea.vue';
import Checkbox from 'dashboard/components-next/checkbox/Checkbox.vue';

const props = defineProps({
  mode: {
    type: String,
    required: true,
    validator: v => ['create', 'edit'].includes(v),
  },
  assistant: {
    type: Object,
    default: null,
  },
});

const emit = defineEmits(['close', 'saved']);

defineOptions({
  name: 'WlAiAssistantDialog',
});

const { t } = useI18n();

const dialogRef = ref(null);
const name = ref('');
const description = ref('');
const productName = ref('');
const featureFaq = ref(false);
const featureMemory = ref(false);
const featureCitations = ref(false);
const isSaving = ref(false);

const reset = () => {
  name.value = '';
  description.value = '';
  productName.value = '';
  featureFaq.value = false;
  featureMemory.value = false;
  featureCitations.value = false;
};

const applyFromAssistant = a => {
  if (!a) {
    reset();
    return;
  }
  name.value = a.name || '';
  description.value = a.description || '';
  productName.value = a.product_name || '';
  const cfg = a.config || {};
  featureFaq.value = !!cfg.feature_faq;
  featureMemory.value = !!cfg.feature_memory;
  featureCitations.value = !!cfg.feature_citations;
};

watch(
  () => [props.mode, props.assistant],
  () => {
    if (props.mode === 'edit' && props.assistant) {
      applyFromAssistant(props.assistant);
    } else {
      reset();
    }
  },
  { immediate: true }
);

const title = computed(() =>
  props.mode === 'edit'
    ? t('WL_AI.ASSISTANTS.DIALOG.EDIT_TITLE')
    : t('WL_AI.ASSISTANTS.DIALOG.CREATE_TITLE')
);

const buildPayload = () => ({
  name: name.value.trim(),
  description: description.value.trim(),
  product_name: productName.value.trim() || null,
  config: {
    feature_faq: featureFaq.value,
    feature_memory: featureMemory.value,
    feature_citations: featureCitations.value,
  },
});

const save = async () => {
  isSaving.value = true;
  try {
    const payload = buildPayload();
    if (props.mode === 'edit' && props.assistant?.id) {
      await wlAiAssistants.update(props.assistant.id, payload);
      useAlert(t('WL_AI.ASSISTANTS.UPDATED'));
    } else {
      await wlAiAssistants.create(payload);
      useAlert(t('WL_AI.ASSISTANTS.CREATED'));
    }
    emit('saved');
    dialogRef.value?.close();
  } catch (error) {
    const msg =
      error.response?.data?.error ||
      error.response?.data?.message ||
      t('WL_AI.ASSISTANTS.SAVE_ERROR');
    useAlert(msg);
  } finally {
    isSaving.value = false;
  }
};

const onClose = () => {
  emit('close');
};

defineExpose({
  open: () => dialogRef.value?.open(),
  close: () => dialogRef.value?.close(),
});
</script>

<template>
  <Dialog
    ref="dialogRef"
    type="edit"
    width="2xl"
    :title="title"
    :description="t('WL_AI.ASSISTANTS.DIALOG.DESCRIPTION')"
    :confirm-button-label="t('WL_AI.ASSISTANTS.DIALOG.SAVE')"
    :cancel-button-label="t('WL_AI.ASSISTANTS.DIALOG.CANCEL')"
    :is-loading="isSaving"
    :disable-confirm-button="!name.trim() || !description.trim() || isSaving"
    overflow-y-auto
    @confirm="save"
    @close="onClose"
  >
    <div class="flex flex-col gap-4">
      <Input
        v-model="name"
        type="text"
        :label="t('WL_AI.ASSISTANTS.DIALOG.NAME_LABEL')"
        :placeholder="t('WL_AI.ASSISTANTS.DIALOG.NAME_PLACEHOLDER')"
      />
      <TextArea
        v-model="description"
        :label="t('WL_AI.ASSISTANTS.DIALOG.DESCRIPTION_LABEL')"
        :placeholder="t('WL_AI.ASSISTANTS.DIALOG.DESCRIPTION_PLACEHOLDER')"
        :max-length="10_000"
        show-character-count
        min-height="5rem"
        resize
      />
      <Input
        v-model="productName"
        type="text"
        :label="t('WL_AI.ASSISTANTS.DIALOG.PRODUCT_NAME_LABEL')"
        :placeholder="t('WL_AI.ASSISTANTS.DIALOG.PRODUCT_NAME_PLACEHOLDER')"
      />
      <div class="flex flex-col gap-2">
        <span class="text-sm font-medium text-n-slate-11">
          {{ t('WL_AI.ASSISTANTS.DIALOG.FEATURES_LABEL') }}
        </span>
        <label class="flex items-center gap-2 cursor-pointer">
          <Checkbox v-model="featureFaq" />
          <span class="text-sm text-n-slate-12">{{
            t('WL_AI.ASSISTANTS.DIALOG.FEATURE_FAQ')
          }}</span>
        </label>
        <label class="flex items-center gap-2 cursor-pointer">
          <Checkbox v-model="featureMemory" />
          <span class="text-sm text-n-slate-12">{{
            t('WL_AI.ASSISTANTS.DIALOG.FEATURE_MEMORY')
          }}</span>
        </label>
        <label class="flex items-center gap-2 cursor-pointer">
          <Checkbox v-model="featureCitations" />
          <span class="text-sm text-n-slate-12">{{
            t('WL_AI.ASSISTANTS.DIALOG.FEATURE_CITATIONS')
          }}</span>
        </label>
      </div>
    </div>
  </Dialog>
</template>
