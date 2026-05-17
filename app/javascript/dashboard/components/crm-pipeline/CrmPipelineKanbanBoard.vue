<script setup>
import { computed } from 'vue';
import { useStore } from 'dashboard/composables/store';
import CrmPipelineKanbanColumn from './CrmPipelineKanbanColumn.vue';

const emit = defineEmits(['deal-click', 'dealMoved']);

const store = useStore();

const stages = computed(() => store.getters['crmPipeline/getStages']);
const getDealsByStage = stageId =>
  store.getters['crmPipeline/getDealsByStage'](stageId);
</script>

<template>
  <div
    class="flex gap-4 items-start h-full min-h-0 overflow-x-auto overflow-y-hidden pb-4"
  >
    <CrmPipelineKanbanColumn
      v-for="stage in stages"
      :key="stage.id"
      :stage="stage"
      :deals="getDealsByStage(stage.id)"
      @deal-click="emit('deal-click', $event)"
      @deal-moved="emit('dealMoved', $event)"
    />
  </div>
</template>
