<script setup>
import { ref } from 'vue';
import { useStore } from 'dashboard/composables/store';
import CrmPipelineDealForm from './CrmPipelineDealForm.vue';
import Button from 'dashboard/components-next/button/Button.vue';

const props = defineProps({
  show: { type: Boolean, default: false },
  stages: { type: Array, default: () => [] },
  agents: { type: Array, default: () => [] },
  initialValues: { type: Object, default: () => ({}) },
  lockedContact: { type: Object, default: null },
});

const emit = defineEmits(['close', 'saved']);

const store = useStore();
const dealFormRef = ref(null);

const onSubmit = async formData => {
  const deal = await store.dispatch('crmPipeline/createDeal', {
    ...props.initialValues,
    ...formData,
    pipeline_id: props.initialValues.pipeline_id,
    stage_id: formData.stage_id,
  });
  emit('saved', deal);
  emit('close');
};
</script>

<template>
  <woot-modal v-if="show" :show="show" @close="emit('close')">
    <woot-modal-header :header-title="$t('CRM_PIPELINE.DEAL.CREATE')" />
    <div class="p-6 space-y-4 max-h-[70vh] overflow-y-auto">
      <CrmPipelineDealForm
        ref="dealFormRef"
        :initial-values="initialValues"
        :locked-contact="lockedContact"
        :stages="stages"
        :agents="agents"
        @submit="onSubmit"
      >
        <template #actions>
          <div class="flex flex-row justify-end w-full gap-2 px-0 py-2">
            <Button
              faded
              slate
              type="button"
              :label="$t('CRM_PIPELINE.ACTIONS.CANCEL')"
              @click="emit('close')"
            />
            <Button type="submit" :label="$t('CRM_PIPELINE.ACTIONS.SAVE')" />
          </div>
        </template>
      </CrmPipelineDealForm>
    </div>
  </woot-modal>
</template>
