<script setup>
import { ref, computed, watch } from 'vue';
import { useStore } from 'dashboard/composables/store';
import { useAlert } from 'dashboard/composables';
import { useI18n } from 'vue-i18n';
import CrmPipelineDealForm from './CrmPipelineDealForm.vue';
import CrmPipelineDealDetailHeader from './CrmPipelineDealDetailHeader.vue';
import CrmPipelineDealSummaryMetrics from './CrmPipelineDealSummaryMetrics.vue';
import CrmPipelineDealTasksSection from './CrmPipelineDealTasksSection.vue';
import CrmPipelineDealDetailSidebar from './CrmPipelineDealDetailSidebar.vue';
import CrmPipelineDealPanelCard from './CrmPipelineDealPanelCard.vue';
import CrmPipelineTaskModal from './CrmPipelineTaskModal.vue';
import CrmPipelineLoseDealModal from './CrmPipelineLoseDealModal.vue';
import Button from 'dashboard/components-next/button/Button.vue';

const props = defineProps({
  deal: { type: Object, default: null },
  show: { type: Boolean, default: false },
  stages: { type: Array, default: () => [] },
  agents: { type: Array, default: () => [] },
  isCreate: { type: Boolean, default: false },
  initialValues: { type: Object, default: () => ({}) },
  lockedContact: { type: Object, default: null },
});

const emit = defineEmits(['close', 'saved', 'win', 'lose']);

const store = useStore();
const { t } = useI18n();
const showLoseModal = ref(false);
const showTaskModal = ref(false);
const editingTask = ref(null);
const isEditing = ref(false);
const dealFormRef = ref(null);

const dealTasks = computed(() => store.getters['crmPipeline/getDealTasks']);
const uiFlags = computed(() => store.getters['crmPipeline/getUIFlags']);

const resetDealViewState = () => {
  isEditing.value = false;
  showLoseModal.value = false;
};

const fetchDealTasks = async () => {
  if (!props.deal?.id) return;
  await store.dispatch('crmPipeline/fetchDealTasks', props.deal.id);
};

watch(
  () => [props.deal?.id, props.show],
  ([dealId, visible]) => {
    if (dealId && visible && !props.isCreate) {
      resetDealViewState();
      fetchDealTasks();
    }
  },
  { immediate: true }
);

const onSubmit = async formData => {
  if (props.isCreate) {
    await store.dispatch('crmPipeline/createDeal', {
      ...props.initialValues,
      ...formData,
      pipeline_id: props.initialValues.pipeline_id,
      stage_id: formData.stage_id,
    });
  } else if (props.deal) {
    await store.dispatch('crmPipeline/updateDeal', {
      id: props.deal.id,
      params: formData,
      pipelineId: props.deal.pipeline.id,
    });
  }
  isEditing.value = false;
  emit('saved');
  emit('close');
};

const onSave = () => {
  dealFormRef.value?.submit();
};

const onWin = () => {
  emit('win', props.deal);
};

const onLoseConfirm = lostReason => {
  emit('lose', { deal: props.deal, lostReason });
  showLoseModal.value = false;
};

const onTaskSaved = async () => {
  await fetchDealTasks();
  emit('saved');
};

const openTaskModal = () => {
  editingTask.value = null;
  showTaskModal.value = true;
};

const onEditTask = task => {
  editingTask.value = task;
  showTaskModal.value = true;
};

const onTaskModalClose = () => {
  showTaskModal.value = false;
  editingTask.value = null;
};

const onCompleteTask = async task => {
  await store.dispatch('crmPipeline/completeTask', {
    id: task.id,
    dealId: props.deal?.id,
  });
  useAlert(t('CRM_PIPELINE.TASKS.COMPLETED'));
  await onTaskSaved();
};

const onCancelTask = async task => {
  await store.dispatch('crmPipeline/cancelTask', {
    id: task.id,
    dealId: props.deal?.id,
  });
  useAlert(t('CRM_PIPELINE.TASKS.CANCELLED'));
  await onTaskSaved();
};
</script>

<template>
  <woot-modal
    v-if="show"
    :show="show"
    :size="isCreate ? '' : 'modal-large'"
    @close="emit('close')"
  >
    <template v-if="isCreate">
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
    </template>

    <template v-else-if="deal">
      <div class="p-6 pt-10 max-h-[90vh] overflow-y-auto bg-n-surface-1">
        <CrmPipelineDealDetailHeader
          :deal="deal"
          @win="onWin"
          @lose="showLoseModal = true"
          @edit="isEditing = true"
        />

        <CrmPipelineDealSummaryMetrics :deal="deal" />

        <div class="grid grid-cols-1 gap-5 lg:grid-cols-[minmax(0,1fr)_20rem]">
          <div class="flex flex-col gap-5 min-w-0">
            <CrmPipelineDealPanelCard
              v-if="!isEditing"
              :title="$t('CRM_PIPELINE.DEAL.DESCRIPTION')"
            >
              <p
                class="text-sm text-n-slate-11 leading-relaxed whitespace-pre-wrap"
              >
                {{ deal.description || $t('CRM_PIPELINE.DEAL.NO_DESCRIPTION') }}
              </p>
            </CrmPipelineDealPanelCard>

            <CrmPipelineDealPanelCard
              v-if="isEditing"
              :title="$t('CRM_PIPELINE.DEAL.EDIT')"
            >
              <CrmPipelineDealForm
                ref="dealFormRef"
                variant="crm-edit"
                :initial-values="deal"
                :stages="stages"
                :agents="agents"
                @submit="onSubmit"
              />
              <div
                class="flex justify-end gap-2 mt-4 pt-4 border-t border-n-weak"
              >
                <Button
                  faded
                  slate
                  type="button"
                  :label="$t('CRM_PIPELINE.ACTIONS.CANCEL')"
                  @click="isEditing = false"
                />
                <Button
                  type="button"
                  :label="$t('CRM_PIPELINE.ACTIONS.SAVE')"
                  @click="onSave"
                />
              </div>
            </CrmPipelineDealPanelCard>

            <CrmPipelineDealTasksSection
              :tasks="dealTasks"
              :no-next-step="deal.no_next_step"
              :is-loading="uiFlags.isFetchingTasks"
              @add="openTaskModal"
              @complete="onCompleteTask"
              @cancel="onCancelTask"
              @edit="onEditTask"
            />
          </div>

          <CrmPipelineDealDetailSidebar :deal="deal" />
        </div>
      </div>
    </template>

    <CrmPipelineTaskModal
      :show="showTaskModal"
      :task="editingTask"
      :locked-deal="deal"
      :agents="agents"
      :deal-id="deal?.id"
      @close="onTaskModalClose"
      @created="onTaskSaved"
      @updated="onTaskSaved"
    />

    <CrmPipelineLoseDealModal
      :show="showLoseModal"
      @close="showLoseModal = false"
      @confirm="onLoseConfirm"
    />
  </woot-modal>
</template>
