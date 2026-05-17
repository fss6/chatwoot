<script setup>
import { ref, computed, watch } from 'vue';
import { useStore } from 'dashboard/composables/store';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import Button from 'dashboard/components-next/button/Button.vue';
import CrmPipelineFormField from './CrmPipelineFormField.vue';

const props = defineProps({
  show: { type: Boolean, default: false },
  pipeline: { type: Object, default: null },
});

const emit = defineEmits(['close', 'saved']);

const store = useStore();
const { t } = useI18n();

const pipelineEditName = ref('');
const pipelineEditDescription = ref('');
const showStageModal = ref(false);
const stageForm = ref({ name: '', stage_type: 'open', position: 0 });

const uiFlags = computed(() => store.getters['crmPipeline/getUIFlags']);

const stageTypeOptions = [
  { value: 'open', labelKey: 'CRM_PIPELINE.SETTINGS.STAGE_TYPE_OPEN' },
  { value: 'won', labelKey: 'CRM_PIPELINE.SETTINGS.STAGE_TYPE_WON' },
  { value: 'lost', labelKey: 'CRM_PIPELINE.SETTINGS.STAGE_TYPE_LOST' },
];

watch(
  () => props.pipeline,
  pipeline => {
    pipelineEditName.value = pipeline?.name || '';
    pipelineEditDescription.value = pipeline?.description || '';
  },
  { immediate: true }
);

const savePipelineName = async () => {
  if (!props.pipeline || !pipelineEditName.value.trim()) return;

  try {
    await store.dispatch('crmPipeline/updatePipeline', {
      id: props.pipeline.id,
      params: {
        name: pipelineEditName.value.trim(),
        description: pipelineEditDescription.value?.trim() || '',
      },
    });
    useAlert(t('CRM_PIPELINE.SETTINGS.PIPELINE_SAVED'));
    emit('saved');
  } catch (error) {
    useAlert(
      error?.message || t('CRM_PIPELINE.SETTINGS.PIPELINE_CREATE_ERROR')
    );
  }
};

const openCreateStage = () => {
  const count = props.pipeline?.stages?.length || 0;
  stageForm.value = { name: '', stage_type: 'open', position: count };
  showStageModal.value = true;
};

const saveStage = async () => {
  if (!props.pipeline || !stageForm.value.name.trim()) return;

  try {
    await store.dispatch('crmPipeline/createStage', {
      pipelineId: props.pipeline.id,
      params: {
        name: stageForm.value.name.trim(),
        stage_type: stageForm.value.stage_type,
        position: stageForm.value.position,
      },
    });
    useAlert(t('CRM_PIPELINE.SETTINGS.STAGE_CREATED'));
    showStageModal.value = false;
    emit('saved');
  } catch (error) {
    useAlert(
      error?.message || t('CRM_PIPELINE.SETTINGS.PIPELINE_CREATE_ERROR')
    );
  }
};

const updateStageField = async (stage, field, value) => {
  await store.dispatch('crmPipeline/updateStage', {
    id: stage.id,
    params: { [field]: value },
  });
  emit('saved');
};

const deleteStage = async stage => {
  // eslint-disable-next-line no-alert
  if (!window.confirm(t('CRM_PIPELINE.SETTINGS.DELETE_STAGE_CONFIRM'))) return;
  await store.dispatch('crmPipeline/deleteStage', stage.id);
  emit('saved');
};
</script>

<template>
  <woot-modal
    v-if="show && pipeline"
    :show="show"
    size="medium"
    @close="emit('close')"
  >
    <woot-modal-header :header-title="pipeline.name" />
    <div class="flex flex-col max-h-[70vh] overflow-y-auto">
      <form
        class="flex flex-col items-start w-full"
        @submit.prevent="savePipelineName"
      >
        <CrmPipelineFormField
          :label="$t('CRM_PIPELINE.SETTINGS.PIPELINE_NAME')"
        >
          <input v-model="pipelineEditName" type="text" required />
        </CrmPipelineFormField>

        <CrmPipelineFormField
          :label="$t('CRM_PIPELINE.SETTINGS.PIPELINE_DESCRIPTION')"
        >
          <textarea v-model="pipelineEditDescription" rows="2" />
        </CrmPipelineFormField>

        <div class="flex justify-end w-full gap-2 px-0 py-2">
          <Button
            type="submit"
            sm
            :label="$t('CRM_PIPELINE.ACTIONS.SAVE')"
            :is-loading="uiFlags.isSaving"
          />
        </div>
      </form>

      <div class="px-6 pb-6 space-y-3 border-t border-n-weak pt-4">
        <div class="flex items-center justify-between gap-2">
          <h3 class="text-sm font-medium text-n-slate-12">
            {{ $t('CRM_PIPELINE.SETTINGS.STAGES') }}
          </h3>
          <Button
            sm
            faded
            :label="$t('CRM_PIPELINE.SETTINGS.ADD_STAGE')"
            @click="openCreateStage"
          />
        </div>

        <ul v-if="pipeline.stages?.length" class="space-y-2">
          <li
            v-for="stage in pipeline.stages"
            :key="stage.id"
            class="flex flex-wrap items-center gap-2 p-3 rounded-lg border border-n-weak bg-n-solid-1"
          >
            <input
              :value="stage.name"
              type="text"
              class="flex-1 min-w-[120px]"
              @change="updateStageField(stage, 'name', $event.target.value)"
            />
            <select
              :value="stage.stage_type"
              class="min-w-[120px]"
              @change="
                updateStageField(stage, 'stage_type', $event.target.value)
              "
            >
              <option
                v-for="opt in stageTypeOptions"
                :key="opt.value"
                :value="opt.value"
              >
                {{ $t(opt.labelKey) }}
              </option>
            </select>
            <Button
              xs
              link
              ruby
              :label="$t('CRM_PIPELINE.SETTINGS.DELETE')"
              @click="deleteStage(stage)"
            />
          </li>
        </ul>
        <p v-else class="text-sm text-n-slate-11">
          {{ $t('CRM_PIPELINE.SETTINGS.NO_STAGES') }}
        </p>
      </div>
    </div>
  </woot-modal>

  <woot-modal
    v-if="showStageModal"
    :show="showStageModal"
    size="small"
    @close="showStageModal = false"
  >
    <woot-modal-header :header-title="$t('CRM_PIPELINE.SETTINGS.ADD_STAGE')" />
    <form class="flex flex-col items-start w-full" @submit.prevent="saveStage">
      <CrmPipelineFormField :label="$t('CRM_PIPELINE.DEAL.STAGE')">
        <input v-model="stageForm.name" type="text" required />
      </CrmPipelineFormField>

      <CrmPipelineFormField :label="$t('CRM_PIPELINE.SETTINGS.STAGE_TYPE')">
        <select v-model="stageForm.stage_type">
          <option
            v-for="opt in stageTypeOptions"
            :key="opt.value"
            :value="opt.value"
          >
            {{ $t(opt.labelKey) }}
          </option>
        </select>
      </CrmPipelineFormField>

      <div class="flex justify-end w-full gap-2 px-0 py-2">
        <Button
          faded
          slate
          type="button"
          :label="$t('CRM_PIPELINE.ACTIONS.CANCEL')"
          @click="showStageModal = false"
        />
        <Button
          type="submit"
          :label="$t('CRM_PIPELINE.ACTIONS.SAVE')"
          :is-loading="uiFlags.isSaving"
        />
      </div>
    </form>
  </woot-modal>
</template>
