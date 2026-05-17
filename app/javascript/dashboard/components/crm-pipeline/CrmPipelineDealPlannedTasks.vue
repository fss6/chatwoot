<script setup>
import { computed } from 'vue';
import CrmPipelineTaskCard from './CrmPipelineTaskCard.vue';

const props = defineProps({
  tasks: { type: Array, default: () => [] },
  isLoading: { type: Boolean, default: false },
});

const emit = defineEmits(['complete', 'cancel', 'edit', 'add']);

const pendingTasks = computed(() =>
  props.tasks.filter(task => task.status === 'pending')
);
</script>

<template>
  <section class="space-y-3">
    <div class="flex items-center justify-between gap-2">
      <h3 class="text-sm font-semibold text-n-slate-12">
        {{ $t('CRM_PIPELINE.DEAL.PLANNED_ACTIVITIES') }}
      </h3>
      <button
        type="button"
        class="text-xs font-medium text-n-blue-11 hover:underline"
        @click="emit('add')"
      >
        {{ $t('CRM_PIPELINE.TASKS.ADD_TASK') }}
      </button>
    </div>

    <p v-if="isLoading" class="text-xs text-n-slate-11">
      {{ $t('CRM_PIPELINE.LOADING') }}
    </p>

    <ul
      v-else-if="pendingTasks.length"
      class="overflow-hidden rounded-xl border border-n-weak divide-y divide-n-weak"
    >
      <li v-for="task in pendingTasks" :key="task.id">
        <CrmPipelineTaskCard
          :task="task"
          @complete="emit('complete', $event)"
          @cancel="emit('cancel', $event)"
          @edit="emit('edit', $event)"
        />
      </li>
    </ul>

    <p v-else class="text-xs text-n-slate-11">
      {{ $t('CRM_PIPELINE.DEAL.NO_PLANNED_ACTIVITIES') }}
    </p>
  </section>
</template>
