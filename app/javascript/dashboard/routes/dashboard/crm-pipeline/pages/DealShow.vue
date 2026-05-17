<script setup>
import { ref, computed, watch, onMounted, onBeforeUnmount } from 'vue';
import { useRoute, useRouter } from 'vue-router';
import { useStore, useMapGetter } from 'dashboard/composables/store';
import { useAccount } from 'dashboard/composables/useAccount';
import { useAlert } from 'dashboard/composables';
import { useI18n } from 'vue-i18n';
import CrmPipelinePageLayout from 'dashboard/components/crm-pipeline/CrmPipelinePageLayout.vue';
import CrmPipelineDealDetailHeader from 'dashboard/components/crm-pipeline/CrmPipelineDealDetailHeader.vue';
import CrmPipelineDealSummaryMetrics from 'dashboard/components/crm-pipeline/CrmPipelineDealSummaryMetrics.vue';
import CrmPipelineDealTasksSection from 'dashboard/components/crm-pipeline/CrmPipelineDealTasksSection.vue';
import CrmPipelineDealDetailSidebar from 'dashboard/components/crm-pipeline/CrmPipelineDealDetailSidebar.vue';
import CrmPipelineDealPanelCard from 'dashboard/components/crm-pipeline/CrmPipelineDealPanelCard.vue';
import CrmPipelineDealDescriptionCard from 'dashboard/components/crm-pipeline/CrmPipelineDealDescriptionCard.vue';
import CrmPipelineDealForm from 'dashboard/components/crm-pipeline/CrmPipelineDealForm.vue';
import CrmPipelineTaskModal from 'dashboard/components/crm-pipeline/CrmPipelineTaskModal.vue';
import CrmPipelineLoseDealModal from 'dashboard/components/crm-pipeline/CrmPipelineLoseDealModal.vue';
import Button from 'dashboard/components-next/button/Button.vue';

const route = useRoute();
const router = useRouter();
const store = useStore();
const { accountScopedRoute } = useAccount();
const { t } = useI18n();

const isEditing = ref(false);
const showLoseModal = ref(false);
const showTaskModal = ref(false);
const editingTask = ref(null);
const dealFormRef = ref(null);

const dealId = computed(() => Number(route.params.dealId));
const deal = computed(() => store.getters['crmPipeline/getCurrentDeal']);
const dealTasks = computed(() => store.getters['crmPipeline/getDealTasks']);
const uiFlags = computed(() => store.getters['crmPipeline/getUIFlags']);
const stages = computed(() => store.getters['crmPipeline/getStages']);
const agents = useMapGetter('agents/getAgents');

const pipelineDealsRoute = computed(() =>
  accountScopedRoute('crm_pipeline_deals')
);

const loadDeal = async () => {
  if (!dealId.value) return;
  const loaded = await store.dispatch('crmPipeline/fetchDeal', dealId.value);
  if (loaded?.pipeline?.id) {
    store.commit('crmPipeline/SET_SELECTED_PIPELINE_ID', loaded.pipeline.id);
  }
  await store.dispatch('crmPipeline/fetchDealTasks', dealId.value);
};

const refreshDeal = async () => {
  await loadDeal();
};

watch(dealId, () => {
  isEditing.value = false;
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

const onSubmit = async formData => {
  if (!deal.value) return;
  await store.dispatch('crmPipeline/updateDeal', {
    id: deal.value.id,
    params: formData,
    pipelineId: deal.value.pipeline.id,
    refreshDeal: true,
  });
  isEditing.value = false;
  useAlert(t('CRM_PIPELINE.DEAL.SAVED'));
};

const onSave = () => {
  dealFormRef.value?.submit();
};

const onWin = async () => {
  if (!deal.value) return;
  await store.dispatch('crmPipeline/winDeal', {
    id: deal.value.id,
    pipelineId: deal.value.pipeline.id,
  });
  router.push(pipelineDealsRoute.value);
};

const onLoseConfirm = async lostReason => {
  if (!deal.value) return;
  await store.dispatch('crmPipeline/loseDeal', {
    id: deal.value.id,
    lostReason,
    pipelineId: deal.value.pipeline.id,
  });
  showLoseModal.value = false;
  router.push(pipelineDealsRoute.value);
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
      <router-link
        :to="pipelineDealsRoute"
        class="inline-flex items-center gap-1.5 text-sm text-n-slate-11 transition-colors hover:text-n-slate-12 w-fit"
      >
        <span class="i-lucide-arrow-left size-4 shrink-0" aria-hidden="true" />
        {{ $t('CRM_PIPELINE.DEAL.BACK_TO_PIPELINE') }}
      </router-link>

      <template v-if="deal">
        <CrmPipelineDealDetailHeader
          page-header
          :deal="deal"
          @win="onWin"
          @lose="showLoseModal = true"
          @edit="isEditing = true"
        />
        <h1 class="text-heading-1 text-n-slate-12 break-words">
          {{ deal.title }}
        </h1>
      </template>
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

    <div v-else-if="deal" class="grid h-full min-h-0 gap-6 lg:grid-cols-12">
      <div class="flex flex-col gap-5 min-w-0 pb-6 lg:col-span-6 xl:col-span-7">
        <CrmPipelineDealSummaryMetrics :deal="deal" />

        <CrmPipelineDealDescriptionCard v-if="!isEditing" :deal="deal" />

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
          <div class="flex justify-end gap-2 mt-4 pt-4 border-t border-n-weak">
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

        <CrmPipelineDealDetailSidebar :deal="deal" />
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
