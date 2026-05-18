<script setup>
import CrmPipelineDealPanelCard from './CrmPipelineDealPanelCard.vue';
import CrmPipelineDealLabels from './CrmPipelineDealLabels.vue';

defineProps({
  dealId: { type: Number, required: true },
  pipelineId: { type: Number, default: null },
});
</script>

<template>
  <CrmPipelineDealPanelCard>
    <template #header>
      <h3 class="text-sm font-bold text-n-slate-12">
        {{ $t('CRM_PIPELINE.DEAL.LABELS') }}
      </h3>
    </template>
    <CrmPipelineDealLabels :deal-id="dealId" :pipeline-id="pipelineId" />
  </CrmPipelineDealPanelCard>
</template>
