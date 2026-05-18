<script setup>
import { ref, computed, watch, onMounted, onBeforeUnmount } from 'vue';
import { useRoute } from 'vue-router';
import { useStore, useMapGetter } from 'dashboard/composables/store';
import { useAccount } from 'dashboard/composables/useAccount';
import { useAlert } from 'dashboard/composables';
import { useI18n } from 'vue-i18n';
import CrmPipelinePageLayout from 'dashboard/components/crm-pipeline/CrmPipelinePageLayout.vue';
import CrmPipelineDealDetailHeader from 'dashboard/components/crm-pipeline/CrmPipelineDealDetailHeader.vue';
import CrmPipelineDealClosedStatusBanner from 'dashboard/components/crm-pipeline/CrmPipelineDealClosedStatusBanner.vue';
import CrmPipelineDealSummaryMetrics from 'dashboard/components/crm-pipeline/CrmPipelineDealSummaryMetrics.vue';
import CrmPipelineDealTasksSection from 'dashboard/components/crm-pipeline/CrmPipelineDealTasksSection.vue';
import CrmPipelineDealDescriptionCard from 'dashboard/components/crm-pipeline/CrmPipelineDealDescriptionCard.vue';
import CrmPipelineDealLabelsCard from 'dashboard/components/crm-pipeline/CrmPipelineDealLabelsCard.vue';
import CrmPipelineDealNotesSection from 'dashboard/components/crm-pipeline/CrmPipelineDealNotesSection.vue';
import CrmPipelineTaskModal from 'dashboard/components/crm-pipeline/CrmPipelineTaskModal.vue';
import CrmPipelineLoseDealModal from 'dashboard/components/crm-pipeline/CrmPipelineLoseDealModal.vue';

const route = useRoute();
const store = useStore();
const { accountScopedRoute } = useAccount();
const { t } = useI18n();

const showLoseModal = ref(false);
const showTaskModal = ref(false);
const editingTask = ref(null);
const isReopening = ref(false);

const dealId = computed(() => Number(route.params.dealId));
const deal = computed(() => store.getters['crmPipeline/getCurrentDeal']);
const dealTasks = computed(() => store.getters['crmPipeline/getDealTasks']);
const uiFlags = computed(() => store.getters['crmPipeline/getUIFlags']);
const agents = useMapGetter('agents/getAgents');

const pipelineDealsRoute = computed(() =>
  accountScopedRoute('crm_pipeline_deals')
);

const stages = computed(() => store.getters['crmPipeline/getStages']);

const firstOpenStage = computed(
  () =>
    [...stages.value]
      .filter(stage => stage.stage_type === 'open')
      .sort((a, b) => a.position - b.position)[0]
);

const loadDeal = async () => {
  if (!dealId.value) return;
  const loaded = await store.dispatch('crmPipeline/fetchDeal', dealId.value);
  if (loaded?.pipeline?.id) {
    store.commit('crmPipeline/SET_SELECTED_PIPELINE_ID', loaded.pipeline.id);
  }
  await store.dispatch('crmPipeline/fetchDealTasks', dealId.value);
  await store.dispatch('crmPipeline/fetchDealNotes', dealId.value);
};

const refreshDeal = async () => {
  await loadDeal();
};

watch(dealId, () => {
  loadDeal();
});

onMounted(async () => {
  await store.dispatch('crmPipeline/fetchPipelines');
  store.dispatch('agents/get');
  await loadDeal();
});

onBeforeUnmount(() => {
  store.dispatch('crmPipeline/clearCurrentDeal');
});

const onWin = async () => {
  if (!deal.value) return;
  await store.dispatch('crmPipeline/winDeal', {
    id: deal.value.id,
    pipelineId: deal.value.pipeline.id,
    refreshDeal: true,
  });
  useAlert(t('CRM_PIPELINE.DEAL.WON_SUCCESS'));
};

const onLoseConfirm = async lostReason => {
  if (!deal.value) return;
  await store.dispatch('crmPipeline/loseDeal', {
    id: deal.value.id,
    lostReason,
    pipelineId: deal.value.pipeline.id,
    refreshDeal: true,
  });
  showLoseModal.value = false;
  useAlert(t('CRM_PIPELINE.DEAL.LOST_SUCCESS'));
};

const onReopen = async () => {
  if (!deal.value || !firstOpenStage.value) return;

  isReopening.value = true;
  try {
    const dealsInStage = store.getters['crmPipeline/getDealsByStage'](
      firstOpenStage.value.id
    );
    await store.dispatch('crmPipeline/moveDeal', {
      id: deal.value.id,
      stageId: firstOpenStage.value.id,
      position: dealsInStage.length,
      pipelineId: deal.value.pipeline.id,
      refreshDeal: true,
    });
    await store.dispatch('crmPipeline/fetchDealTasks', dealId.value);
    useAlert(t('CRM_PIPELINE.DEAL.REOPEN_SUCCESS'));
  } finally {
    isReopening.value = false;
  }
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

const onTaskSaved = async () => {
  await store.dispatch('crmPipeline/fetchDealTasks', dealId.value);
  await refreshDeal();
};

const onCompleteTask = async task => {
  await store.dispatch('crmPipeline/completeTask', {
    id: task.id,
    dealId: dealId.value,
  });
  useAlert(t('CRM_PIPELINE.TASKS.COMPLETED'));
  await onTaskSaved();
};

const onCancelTask = async task => {
  await store.dispatch('crmPipeline/cancelTask', {
    id: task.id,
    dealId: dealId.value,
  });
  useAlert(t('CRM_PIPELINE.TASKS.CANCELLED'));
  await onTaskSaved();
};
</script>

<template>
  <CrmPipelinePageLayout title="" full-width>
    <template v-if="deal || uiFlags.isFetchingDeal" #header>
      <CrmPipelineDealDetailHeader
        v-if="deal"
        :deal="deal"
        :pipeline-deals-route="pipelineDealsRoute"
        :is-reopening="isReopening"
        @win="onWin"
        @lose="showLoseModal = true"
        @reopen="onReopen"
      />
      <p v-else class="text-sm text-n-slate-11">
        {{ $t('CRM_PIPELINE.LOADING') }}
      </p>
    </template>

    <div
      v-if="uiFlags.isFetchingDeal && !deal"
      class="flex items-center justify-center min-h-[320px] text-sm text-n-slate-11"
    >
      {{ $t('CRM_PIPELINE.LOADING') }}
    </div>

    <div v-else-if="deal" class="grid gap-6 lg:grid-cols-12">
      <div class="flex flex-col gap-5 min-w-0 pb-6 lg:col-span-6 xl:col-span-7">
        <CrmPipelineDealClosedStatusBanner :deal="deal" />

        <CrmPipelineDealSummaryMetrics :deal="deal" />

        <CrmPipelineDealLabelsCard
          :deal-id="deal.id"
          :pipeline-id="deal.pipeline?.id"
        />

        <CrmPipelineDealDescriptionCard :deal="deal" />

        <CrmPipelineDealNotesSection :deal-id="deal.id" />
      </div>

      <aside
        class="flex min-h-0 flex-col lg:col-span-6 xl:col-span-5 lg:sticky lg:top-0 lg:max-h-[calc(100vh-10rem)]"
      >
        <CrmPipelineDealTasksSection
          fill-column
          title-key="CRM_PIPELINE.DEAL.PLANNED_ACTIVITIES"
          :tasks="dealTasks"
          :no-next-step="deal.no_next_step"
          :is-loading="uiFlags.isFetchingTasks"
          @add="openTaskModal"
          @complete="onCompleteTask"
          @cancel="onCancelTask"
          @edit="onEditTask"
        />
      </aside>
    </div>

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
  </CrmPipelinePageLayout>
</template>
