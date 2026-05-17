<script setup>
import { ref, watch } from 'vue';
import Button from 'dashboard/components-next/button/Button.vue';

const props = defineProps({
  show: { type: Boolean, default: false },
});

const emit = defineEmits(['close', 'confirm']);

const lostReason = ref('');

watch(
  () => props.show,
  visible => {
    if (visible) {
      lostReason.value = '';
    }
  }
);

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
  <woot-modal v-if="show" :show="show" size="medium" @close="onClose">
    <woot-modal-header :header-title="$t('CRM_PIPELINE.DEAL.LOSE')" />
    <div class="p-6 space-y-4">
      <label class="flex flex-col gap-1.5">
        <span class="text-sm text-n-slate-11">
          {{ $t('CRM_PIPELINE.DEAL.LOST_REASON') }}
        </span>
        <textarea
          v-model="lostReason"
          rows="3"
          class="w-full text-sm rounded-lg border border-n-weak bg-n-alpha-1 px-3 py-2 resize-none"
          :placeholder="$t('CRM_PIPELINE.DEAL.LOST_REASON_PLACEHOLDER')"
        />
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
