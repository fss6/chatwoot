<script setup>
import { ref, computed, watch } from 'vue';
import { useStore } from 'dashboard/composables/store';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import Button from 'dashboard/components-next/button/Button.vue';
import CrmPipelineTaskForm from './CrmPipelineTaskForm.vue';

const props = defineProps({
  show: { type: Boolean, default: false },
  task: { type: Object, default: null },
  lockedDeal: { type: Object, default: null },
  lockedContact: { type: Object, default: null },
  lockedConversationId: { type: [Number, String], default: null },
  agents: { type: Array, default: () => [] },
  deals: { type: Array, default: () => [] },
  listParams: { type: Object, default: () => ({}) },
  dealId: { type: [Number, String], default: null },
});

const emit = defineEmits(['close', 'created', 'updated']);

const store = useStore();
const { t } = useI18n();
const formRef = ref(null);

const uiFlags = computed(() => store.getters['crmPipeline/getUIFlags']);
const isEditing = computed(() => Boolean(props.task?.id));

const modalTitle = computed(() =>
  isEditing.value
    ? t('CRM_PIPELINE.TASKS.EDIT')
    : t('CRM_PIPELINE.TASKS.CREATE')
);

const onSubmit = async taskPayload => {
  try {
    if (isEditing.value) {
      await store.dispatch('crmPipeline/updateTask', {
        id: props.task.id,
        task: taskPayload,
        listParams: props.listParams,
        dealId: props.dealId,
      });
      useAlert(t('CRM_PIPELINE.TASKS.UPDATED'));
      emit('updated');
    } else {
      await store.dispatch('crmPipeline/createTask', {
        task: taskPayload,
        listParams: props.listParams,
        dealId: props.dealId,
      });
      useAlert(t('CRM_PIPELINE.TASKS.CREATED'));
      formRef.value?.reset();
      emit('created');
    }
    emit('close');
  } catch (error) {
    useAlert(
      error?.message ||
        t(
          isEditing.value
            ? 'CRM_PIPELINE.TASKS.UPDATE_ERROR'
            : 'CRM_PIPELINE.TASKS.CREATE_ERROR'
        )
    );
  }
};

watch(
  () => props.show,
  visible => {
    if (visible && !props.task) {
      formRef.value?.reset();
    } else if (visible && props.task) {
      formRef.value?.populateFromTask(props.task);
    }
  }
);
</script>

<template>
  <woot-modal v-if="show" :show="show" size="medium" @close="emit('close')">
    <woot-modal-header :header-title="modalTitle" />
    <CrmPipelineTaskForm
      ref="formRef"
      :initial-task="task"
      :locked-deal="lockedDeal"
      :locked-contact="lockedContact"
      :locked-conversation-id="lockedConversationId"
      :agents="agents"
      :deals="deals"
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
          <Button
            type="submit"
            :label="$t('CRM_PIPELINE.ACTIONS.SAVE')"
            :is-loading="uiFlags.isSaving"
          />
        </div>
      </template>
    </CrmPipelineTaskForm>
  </woot-modal>
</template>
