<script setup>
import { ref, watch, nextTick } from 'vue';
import Button from 'dashboard/components-next/button/Button.vue';

const props = defineProps({
  show: { type: Boolean, default: false },
});

const emit = defineEmits(['close', 'confirm']);

const LOST_REASON_MAX_LENGTH = 10_000;

const lostReason = ref('');
const textareaRef = ref(null);

const adjustHeight = () => {
  if (!textareaRef.value) return;

  textareaRef.value.style.height = 'auto';
  textareaRef.value.style.height = `${textareaRef.value.scrollHeight}px`;
};

watch(
  () => props.show,
  visible => {
    if (visible) {
      lostReason.value = '';
      nextTick(adjustHeight);
    }
  }
);

watch(lostReason, () => {
  nextTick(adjustHeight);
});

const onInput = () => {
  nextTick(adjustHeight);
};

const onConfirm = () => {
  if (!lostReason.value.trim()) return;
  emit('confirm', lostReason.value.trim());
};

const onClose = () => {
  lostReason.value = '';
  emit('close');
};
</script>

<template>
  <woot-modal :show="show" size="medium" @close="onClose">
    <woot-modal-header :header-title="$t('CRM_PIPELINE.DEAL.LOSE')" />
    <div class="p-6 space-y-4">
      <label class="flex flex-col gap-1.5">
        <span class="text-sm text-n-slate-11">
          {{ $t('CRM_PIPELINE.DEAL.LOST_REASON') }}
        </span>
        <textarea
          ref="textareaRef"
          v-model="lostReason"
          rows="1"
          :maxlength="LOST_REASON_MAX_LENGTH"
          class="w-full min-h-[5.5rem] max-h-[16rem] overflow-y-auto text-sm rounded-lg border border-n-weak bg-n-alpha-1 px-3 py-2 resize-none"
          :placeholder="$t('CRM_PIPELINE.DEAL.LOST_REASON_PLACEHOLDER')"
          @input="onInput"
        />
        <span
          class="text-xs text-n-slate-11 tabular-nums ltr:text-right rtl:text-left"
        >
          {{
            $t('CRM_PIPELINE.DEAL.LOST_REASON_CHAR_COUNT', {
              current: lostReason.length,
              max: LOST_REASON_MAX_LENGTH,
            })
          }}
        </span>
      </label>
      <div class="flex justify-end gap-2">
        <Button
          faded
          slate
          type="button"
          :label="$t('CRM_PIPELINE.ACTIONS.CANCEL')"
          @click="onClose"
        />
        <Button
          ruby
          type="button"
          :label="$t('CRM_PIPELINE.DEAL.LOSE')"
          :disabled="!lostReason.trim()"
          @click="onConfirm"
        />
      </div>
    </div>
  </woot-modal>
</template>
