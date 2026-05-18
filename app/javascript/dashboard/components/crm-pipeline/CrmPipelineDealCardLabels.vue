<script setup>
import { computed } from 'vue';
import { useMapGetter } from 'dashboard/composables/store';

const props = defineProps({
  labelTitles: { type: Array, default: () => [] },
  maxVisible: { type: Number, default: 2 },
});

const accountLabels = useMapGetter('labels/getLabels');

const activeLabels = computed(() =>
  accountLabels.value.filter(({ title }) => props.labelTitles.includes(title))
);

const visibleLabels = computed(() =>
  activeLabels.value.slice(0, props.maxVisible)
);

const hiddenCount = computed(
  () => activeLabels.value.length - visibleLabels.value.length
);
</script>

<template>
  <div
    v-if="activeLabels.length"
    class="flex flex-wrap items-center gap-1 mt-2"
  >
    <span
      v-for="label in visibleLabels"
      :key="label.id"
      class="inline-flex max-w-full items-center gap-1 rounded-full bg-n-alpha-2 px-2 py-0.5 text-[10px] font-medium text-n-slate-12"
    >
      <span
        class="size-1.5 shrink-0 rounded-sm"
        :style="{ backgroundColor: label.color }"
      />
      <span class="truncate">{{ label.title }}</span>
    </span>
    <span
      v-if="hiddenCount > 0"
      class="inline-flex rounded-full bg-n-alpha-2 px-1.5 py-0.5 text-[10px] font-medium text-n-slate-11"
    >
      +{{ hiddenCount }}
    </span>
  </div>
</template>
