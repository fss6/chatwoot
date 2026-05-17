<script setup>
import { computed } from 'vue';

const props = defineProps({
  stages: { type: Array, default: () => [] },
});

const modelValue = defineModel({ type: [Number, String], default: null });

const sortedStages = computed(() =>
  [...props.stages].sort((a, b) => a.position - b.position)
);

const stageButtonClass = stage => {
  const isActive = stage.id === modelValue.value;
  const type = stage.stage_type;

  if (isActive) {
    if (type === 'won')
      return 'bg-n-teal-3 text-n-teal-11 border-n-teal-8 z-[1]';
    if (type === 'lost')
      return 'bg-n-ruby-3 text-n-ruby-11 border-n-ruby-8 z-[1]';
    return 'bg-n-blue-3 text-n-blue-11 border-n-blue-8 z-[1]';
  }

  return 'bg-n-solid-2 text-n-slate-11 border-n-weak hover:bg-n-alpha-2';
};
</script>

<template>
  <div
    class="flex flex-1 min-w-0 max-w-full overflow-x-auto rounded-lg"
    role="tablist"
  >
    <button
      v-for="stage in sortedStages"
      :key="stage.id"
      type="button"
      role="tab"
      :aria-selected="stage.id === modelValue"
      class="flex-1 min-w-[4.5rem] max-w-[9rem] px-2 py-1.5 text-xs font-medium truncate border -ml-px first:ml-0 first:rounded-l-lg last:rounded-r-lg transition-colors"
      :class="stageButtonClass(stage)"
      :title="stage.name"
      @click="modelValue = stage.id"
    >
      {{ stage.name }}
    </button>
  </div>
</template>
