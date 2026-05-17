<script setup>
import { ref, computed, onMounted } from 'vue';
import { useStore, useMapGetter } from 'dashboard/composables/store';
import { useAdmin } from 'dashboard/composables/useAdmin';
import { useAccount } from 'dashboard/composables/useAccount';
import CrmPipelinePageLayout from 'dashboard/components/crm-pipeline/CrmPipelinePageLayout.vue';
import CrmPipelineKanbanBoard from 'dashboard/components/crm-pipeline/CrmPipelineKanbanBoard.vue';
import CrmPipelineDealModal from 'dashboard/components/crm-pipeline/CrmPipelineDealModal.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import Select from 'dashboard/components-next/select/Select.vue';

const store = useStore();
const { isAdmin } = useAdmin();
const { accountScopedRoute } = useAccount();
const selectedDeal = ref(null);
const showDealModal = ref(false);
const showCreateModal = ref(false);

const pipelines = computed(() => store.getters['crmPipeline/getPipelines']);
const selectedPipelineId = computed({
  get: () => store.getters['crmPipeline/getSelectedPipeline']?.id,
  set: id => store.commit('crmPipeline/SET_SELECTED_PIPELINE_ID', id),
});
const selectedPipeline = computed(
  () => store.getters['crmPipeline/getSelectedPipeline']
);
const pipelineOptions = computed(() =>
  pipelines.value.map(p => ({ value: p.id, label: p.name }))
);
const stages = computed(() => store.getters['crmPipeline/getStages']);
const agents = useMapGetter('agents/getAgents');
const uiFlags = computed(() => store.getters['crmPipeline/getUIFlags']);

const loadDeals = async () => {
  const pipeline = store.getters['crmPipeline/getSelectedPipeline'];
  if (pipeline) {
    await store.dispatch('crmPipeline/fetchDeals', {
      pipeline_id: pipeline.id,
    });
  }
};

const load = async () => {
  await store.dispatch('crmPipeline/fetchPipelines');
  await loadDeals();
};

const onPipelineChange = async pipelineId => {
  store.commit('crmPipeline/SET_SELECTED_PIPELINE_ID', pipelineId);
  await loadDeals();
};

const onDealClick = deal => {
  selectedDeal.value = deal;
  showDealModal.value = true;
};

const onDealMoved = async ({ deal, stageId, position }) => {
  await store.dispatch('crmPipeline/moveDeal', {
    id: deal.id,
    stageId,
    position,
    pipelineId: selectedPipeline.value?.id,
  });
};

const onWin = async deal => {
  await store.dispatch('crmPipeline/winDeal', {
    id: deal.id,
    pipelineId: selectedPipeline.value?.id,
  });
  showDealModal.value = false;
};

const onLose = async ({ deal, lostReason }) => {
  await store.dispatch('crmPipeline/loseDeal', {
    id: deal.id,
    lostReason,
    pipelineId: selectedPipeline.value?.id,
  });
  showDealModal.value = false;
};

onMounted(() => {
  store.dispatch('agents/get');
  load();
});
</script>

<template>
  <CrmPipelinePageLayout
    :title="$t('CRM_PIPELINE.DEALS.TITLE')"
    :description="$t('CRM_PIPELINE.DEALS.SUBTITLE')"
    full-width
  >
    <template #actions>
      <router-link
        v-if="isAdmin"
        v-slot="{ navigate }"
        :to="accountScopedRoute('crm_pipeline_settings')"
        custom
      >
        <Button
          sm
          faded
          :label="$t('CRM_PIPELINE.SETTINGS.MANAGE_PIPELINES')"
          @click="navigate"
        />
      </router-link>
      <Button
        sm
        :label="$t('CRM_PIPELINE.DEAL.CREATE')"
        :disabled="!pipelines.length"
        @click="showCreateModal = true"
      />
    </template>

    <template #toolbar>
      <div v-if="pipelines.length" class="flex flex-wrap items-center gap-3">
        <Select
          v-model="selectedPipelineId"
          :options="pipelineOptions"
          class="w-56"
          @update:model-value="onPipelineChange"
        />
      </div>
    </template>

    <div
      v-if="!pipelines.length && !uiFlags.isFetchingPipelines"
      class="flex flex-col items-center justify-center gap-4 py-20 text-center"
    >
      <p class="text-body-main text-n-slate-11 max-w-md">
        {{ $t('CRM_PIPELINE.DEALS.NO_PIPELINES') }}
      </p>
      <router-link
        v-if="isAdmin"
        v-slot="{ navigate }"
        :to="accountScopedRoute('crm_pipeline_settings')"
        custom
      >
        <Button
          sm
          :label="$t('CRM_PIPELINE.SETTINGS.CREATE_PIPELINE')"
          @click="navigate"
        />
      </router-link>
    </div>

    <div
      v-else-if="uiFlags.isFetchingDeals"
      class="flex items-center justify-center h-full min-h-[320px] text-n-slate-11 text-body-main"
    >
      {{ $t('CRM_PIPELINE.LOADING') }}
    </div>

    <CrmPipelineKanbanBoard
      v-else
      class="flex-1 min-h-[280px]"
      @deal-click="onDealClick"
      @deal-moved="onDealMoved"
    />

    <CrmPipelineDealModal
      :show="showDealModal"
      :deal="selectedDeal"
      :stages="stages"
      :agents="agents"
      @close="showDealModal = false"
      @win="onWin"
      @lose="onLose"
      @saved="load"
    />

    <CrmPipelineDealModal
      :show="showCreateModal"
      is-create
      :stages="stages"
      :agents="agents"
      :initial-values="{
        pipeline_id: selectedPipeline?.id,
        stage_id: stages[0]?.id,
      }"
      @close="showCreateModal = false"
      @saved="load"
    />
  </CrmPipelinePageLayout>
</template>
