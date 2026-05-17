<script setup>
import { computed } from 'vue';
import Button from 'dashboard/components-next/button/Button.vue';
import CrmPipelineDealPanelCard from './CrmPipelineDealPanelCard.vue';
import CrmPipelineTaskCard from './CrmPipelineTaskCard.vue';

const props = defineProps({
  tasks: { type: Array, default: () => [] },
  isLoading: { type: Boolean, default: false },
  noNextStep: { type: Boolean, default: false },
});

const emit = defineEmits(['add', 'complete', 'cancel', 'edit']);

const pendingTasks = computed(() =>
  props.tasks.filter(task => task.status === 'pending')
);

const showNoNextStepAlert = computed(
  () => props.noNextStep && !props.isLoading && !pendingTasks.value.length
);
</script>

<template>
  <CrmPipelineDealPanelCard>
    <template #header>
      <h3 class="text-sm font-bold text-n-slate-12">
        {{ $t('CRM_PIPELINE.TASKS.TITLE') }}
      </h3>
      <Button
        sm
        slate
        icon="i-lucide-plus"
        :label="$t('CRM_PIPELINE.TASKS.CREATE')"
        @click="emit('add')"
      />
    </template>

    <p v-if="isLoading" class="text-sm text-n-slate-11">
      {{ $t('CRM_PIPELINE.LOADING') }}
    </p>

    <div v-else-if="pendingTasks.length" class="flex flex-col gap-3">
      <CrmPipelineTaskCard
        v-for="task in pendingTasks"
        :key="task.id"
        :task="task"
        @complete="emit('complete', $event)"
        @cancel="emit('cancel', $event)"
        @edit="emit('edit', $event)"
      />
    </div>

    <div
      v-else-if="showNoNextStepAlert"
      class="rounded-2xl border border-n-ruby-4 bg-n-ruby-3 p-3 text-sm font-medium text-n-ruby-11"
    >
      {{ $t('CRM_PIPELINE.DEAL.NO_NEXT_STEP_ALERT') }}
    </div>

    <p v-else class="text-sm text-n-slate-11">
      {{ $t('CRM_PIPELINE.DEAL.NO_PLANNED_ACTIVITIES') }}
    </p>
  </CrmPipelineDealPanelCard>
</template>
