<script setup>
import { computed, watch, onMounted, ref } from 'vue';
import { useMapGetter, useStore } from 'dashboard/composables/store';
import LabelItem from 'dashboard/components-next/label/LabelItem.vue';
import AddLabel from 'dashboard/components-next/label/AddLabel.vue';

const props = defineProps({
  dealId: { type: Number, required: true },
  pipelineId: { type: Number, default: null },
});

const store = useStore();
const hoveredLabel = ref(null);

const allLabels = useMapGetter('labels/getLabels');
const dealLabelTitles = useMapGetter('dealLabels/getDealLabels');

const savedLabels = computed(() => {
  const titles = dealLabelTitles.value(props.dealId);
  return allLabels.value.filter(({ title }) => titles.includes(title));
});

const labelMenuItems = computed(() =>
  allLabels.value
    ?.map(label => ({
      label: label.title,
      value: label.id,
      thumbnail: { name: label.title, color: label.color },
      isSelected: savedLabels.value.some(saved => saved.id === label.id),
      action: 'dealLabel',
    }))
    .toSorted((a, b) => Number(a.isSelected) - Number(b.isSelected))
);

const fetchLabels = async dealId => {
  if (!dealId) return;
  await store.dispatch('dealLabels/get', dealId);
};

const updateLabels = async updatedTitles => {
  await store.dispatch('dealLabels/update', {
    dealId: props.dealId,
    labels: updatedTitles,
    pipelineId: props.pipelineId,
  });
};

const handleLabelAction = async ({ value }) => {
  const selectedLabel = allLabels.value.find(label => label.id === value);
  if (!selectedLabel) return;

  const currentTitles = savedLabels.value.map(label => label.title);
  const updatedTitles = currentTitles.includes(selectedLabel.title)
    ? currentTitles.filter(title => title !== selectedLabel.title)
    : [...currentTitles, selectedLabel.title];

  await updateLabels(updatedTitles);
};

const handleRemoveLabel = label => handleLabelAction({ value: label.id });

watch(
  () => props.dealId,
  (newVal, oldVal) => {
    if (newVal && newVal !== oldVal) fetchLabels(newVal);
  }
);

onMounted(() => {
  store.dispatch('labels/get');
  fetchLabels(props.dealId);
});

const handleMouseLeave = () => {
  hoveredLabel.value = null;
};

const handleLabelHover = labelId => {
  hoveredLabel.value = labelId;
};
</script>

<template>
  <div class="flex flex-wrap items-center gap-2" @mouseleave="handleMouseLeave">
    <LabelItem
      v-for="label in savedLabels"
      :key="label.id"
      :label="label"
      :is-hovered="hoveredLabel === label.id"
      @remove="handleRemoveLabel"
      @hover="handleLabelHover(label.id)"
    />
    <AddLabel
      :label-menu-items="labelMenuItems"
      @update-label="handleLabelAction"
    />
  </div>
</template>
