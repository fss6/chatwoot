<script setup>
import { ref, watch, computed } from 'vue';
import { useI18n } from 'vue-i18n';
import draggable from 'vuedraggable';
import CrmPipelineDealCard from './CrmPipelineDealCard.vue';
import { formatStageTotal } from 'dashboard/composables/useCrmDealCardPresentation';

const props = defineProps({
  stage: { type: Object, required: true },
  deals: { type: Array, default: () => [] },
});

const emit = defineEmits(['deal-click', 'dealMoved']);

const { t } = useI18n();

const localDeals = ref([...props.deals]);

watch(
  () => props.deals,
  newDeals => {
    localDeals.value = [...newDeals];
  },
  { deep: true }
);

const onChange = event => {
  if (event.added) {
    const deal = event.added.element;
    emit('dealMoved', {
      deal,
      stageId: props.stage.id,
      position: event.added.newIndex,
    });
  }
};

const stageTotal = computed(() => formatStageTotal(props.deals));

const dealCountLabel = computed(() =>
  t('CRM_PIPELINE.DEALS.COLUMN_COUNT', { n: props.deals.length })
);
</script>

<template>
  <section
    class="flex flex-col w-[17.5rem] shrink-0 max-h-[calc(100vh-14rem)] rounded-2xl border border-n-weak bg-n-alpha-2 p-3"
  >
    <header class="flex flex-col gap-0.5 px-1 pb-3 shrink-0">
      <div class="flex items-start justify-between gap-2">
        <h3 class="text-sm font-semibold text-n-slate-12 truncate">
          {{ stage.name }}
        </h3>
        <span
          v-if="stageTotal"
          class="shrink-0 rounded-full bg-n-solid-1 px-2 py-1 text-xs font-medium tabular-nums text-n-slate-11 shadow-sm"
        >
          {{ stageTotal }}
        </span>
      </div>
      <p class="text-xs text-n-slate-11">
        {{ dealCountLabel }}
      </p>
    </header>
    <draggable
      v-model="localDeals"
      group="crm-deals"
      item-key="id"
      :animation="150"
      ghost-class="opacity-50"
      class="flex flex-col gap-3 overflow-y-auto flex-1 min-h-[3rem]"
      @change="onChange"
    >
      <template #item="{ element }">
        <CrmPipelineDealCard
          :deal="element"
          @click="emit('deal-click', element)"
        />
      </template>
    </draggable>
  </section>
</template>
