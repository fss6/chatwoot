<script setup>
import { ref, watch, toRef } from 'vue';
import { useStore } from 'dashboard/composables/store';
import { useAlert } from 'dashboard/composables';
import { useI18n } from 'vue-i18n';
import { useCrmDealClosedState } from 'dashboard/composables/useCrmDealClosedState';
import CrmPipelineDealPanelCard from './CrmPipelineDealPanelCard.vue';
import Button from 'dashboard/components-next/button/Button.vue';

const props = defineProps({
  deal: { type: Object, required: true },
});

const { isReadOnly } = useCrmDealClosedState(toRef(props, 'deal'));

const store = useStore();
const { t } = useI18n();

const isEditing = ref(false);
const draft = ref('');
const isSaving = ref(false);

watch(
  () => props.deal?.description,
  value => {
    if (!isEditing.value) {
      draft.value = value || '';
    }
  },
  { immediate: true }
);

watch(
  () => props.deal?.id,
  () => {
    isEditing.value = false;
    draft.value = props.deal?.description || '';
  }
);

const startEdit = () => {
  if (isReadOnly.value) return;
  draft.value = props.deal.description || '';
  isEditing.value = true;
};

const cancelEdit = () => {
  draft.value = props.deal.description || '';
  isEditing.value = false;
};

const save = async () => {
  isSaving.value = true;
  try {
    await store.dispatch('crmPipeline/updateDeal', {
      id: props.deal.id,
      params: { description: draft.value },
      pipelineId: props.deal.pipeline.id,
      refreshDeal: true,
    });
    isEditing.value = false;
    useAlert(t('CRM_PIPELINE.DEAL.SAVED'));
  } finally {
    isSaving.value = false;
  }
};
</script>

<template>
  <CrmPipelineDealPanelCard>
    <template #header>
      <h3 class="text-sm font-bold text-n-slate-12">
        {{ $t('CRM_PIPELINE.DEAL.DESCRIPTION') }}
      </h3>
      <button
        v-if="!isEditing && !isReadOnly"
        type="button"
        class="inline-flex items-center gap-1 text-xs text-n-slate-11 transition-colors hover:text-n-slate-12 shrink-0"
        @click="startEdit"
      >
        <span class="i-lucide-pencil size-3.5" aria-hidden="true" />
        {{ $t('CRM_PIPELINE.TASKS.EDIT_ACTION') }}
      </button>
    </template>

    <template v-if="isEditing">
      <textarea
        v-model="draft"
        rows="6"
        class="w-full text-sm rounded-lg border border-n-weak bg-n-solid-1 px-3 py-2 resize-y min-h-[6rem] text-n-slate-12 leading-relaxed"
        :placeholder="$t('CRM_PIPELINE.DEAL.DESCRIPTION_PLACEHOLDER')"
      />
      <div class="flex justify-end gap-2 mt-3">
        <Button
          faded
          slate
          sm
          type="button"
          :label="$t('CRM_PIPELINE.ACTIONS.CANCEL')"
          :disabled="isSaving"
          @click="cancelEdit"
        />
        <Button
          sm
          type="button"
          :label="$t('CRM_PIPELINE.ACTIONS.SAVE')"
          :is-loading="isSaving"
          @click="save"
        />
      </div>
    </template>
    <p
      v-else
      class="text-sm text-n-slate-11 leading-relaxed whitespace-pre-wrap break-words"
    >
      {{ deal.description || $t('CRM_PIPELINE.DEAL.NO_DESCRIPTION') }}
    </p>
  </CrmPipelineDealPanelCard>
</template>
