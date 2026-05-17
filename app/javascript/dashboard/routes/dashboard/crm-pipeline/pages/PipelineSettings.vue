<script setup>
import { ref, computed, onBeforeMount } from 'vue';
import { useStore } from 'dashboard/composables/store';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import SettingsLayout from '../../settings/SettingsLayout.vue';
import BaseSettingsHeader from '../../settings/components/BaseSettingsHeader.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import PipelineEditModal from 'dashboard/components/crm-pipeline/PipelineEditModal.vue';
import CrmPipelineFormField from 'dashboard/components/crm-pipeline/CrmPipelineFormField.vue';
import {
  BaseTable,
  BaseTableRow,
  BaseTableCell,
} from 'dashboard/components-next/table';

const store = useStore();
const { t } = useI18n();

const searchQuery = ref('');
const showAddPopup = ref(false);
const showEditPopup = ref(false);
const showDeleteConfirmationPopup = ref(false);
const selectedPipeline = ref(null);
const pipelineForm = ref({ name: '', description: '' });
const loading = ref({});

const pipelines = computed(() => store.getters['crmPipeline/getPipelines']);
const uiFlags = computed(() => store.getters['crmPipeline/getUIFlags']);

const filteredRecords = computed(() => {
  const query = searchQuery.value.trim().toLowerCase();
  if (!query) return pipelines.value;
  return pipelines.value.filter(
    pipeline =>
      pipeline.name?.toLowerCase().includes(query) ||
      pipeline.description?.toLowerCase().includes(query)
  );
});

const deleteMessage = computed(() => ` ${selectedPipeline.value?.name}?`);

const tableHeaders = computed(() => [
  t('CRM_PIPELINE.SETTINGS.LIST.TABLE_HEADER.NAME'),
  t('CRM_PIPELINE.SETTINGS.LIST.TABLE_HEADER.DESCRIPTION'),
  t('CRM_PIPELINE.SETTINGS.LIST.TABLE_HEADER.STAGES'),
  t('CRM_PIPELINE.SETTINGS.LIST.TABLE_HEADER.ACTION'),
]);

const openAddPopup = () => {
  pipelineForm.value = { name: '', description: '' };
  showAddPopup.value = true;
};

const hideAddPopup = () => {
  showAddPopup.value = false;
};

const openEditPopup = pipeline => {
  selectedPipeline.value = pipeline;
  showEditPopup.value = true;
};

const hideEditPopup = () => {
  showEditPopup.value = false;
};

const openDeletePopup = pipeline => {
  selectedPipeline.value = pipeline;
  showDeleteConfirmationPopup.value = true;
};

const closeDeletePopup = () => {
  showDeleteConfirmationPopup.value = false;
};

const savePipeline = async () => {
  const name = pipelineForm.value.name.trim();
  if (!name) return;

  try {
    await store.dispatch('crmPipeline/createPipeline', {
      name,
      description: pipelineForm.value.description?.trim() || '',
    });
    useAlert(t('CRM_PIPELINE.SETTINGS.PIPELINE_CREATED'));
    hideAddPopup();
  } catch (error) {
    useAlert(
      error?.message || t('CRM_PIPELINE.SETTINGS.PIPELINE_CREATE_ERROR')
    );
  }
};

const deletePipeline = async id => {
  try {
    await store.dispatch('crmPipeline/deletePipeline', id);
    useAlert(t('CRM_PIPELINE.SETTINGS.PIPELINE_DELETED'));
  } catch (error) {
    useAlert(
      error?.message || t('CRM_PIPELINE.SETTINGS.PIPELINE_CREATE_ERROR')
    );
  } finally {
    loading.value[id] = false;
  }
};

const confirmDeletion = () => {
  loading.value[selectedPipeline.value.id] = true;
  closeDeletePopup();
  deletePipeline(selectedPipeline.value.id);
};

const onPipelineSaved = async () => {
  await store.dispatch('crmPipeline/fetchPipelines');
  if (selectedPipeline.value?.id) {
    selectedPipeline.value =
      pipelines.value.find(p => p.id === selectedPipeline.value.id) ||
      selectedPipeline.value;
  }
};

onBeforeMount(() => {
  store.dispatch('crmPipeline/fetchPipelines');
});
</script>

<template>
  <div class="flex flex-col h-full w-full px-4 font-inter">
    <SettingsLayout
      :is-loading="uiFlags.isFetchingPipelines"
      :loading-message="$t('CRM_PIPELINE.LOADING')"
      :no-records-found="!pipelines.length"
      :no-records-message="$t('CRM_PIPELINE.SETTINGS.LIST.EMPTY')"
    >
      <template #header>
        <BaseSettingsHeader
          v-model:search-query="searchQuery"
          :title="$t('CRM_PIPELINE.SETTINGS.TITLE')"
          :description="$t('CRM_PIPELINE.SETTINGS.SUBTITLE')"
          :search-placeholder="$t('CRM_PIPELINE.SETTINGS.SEARCH_PLACEHOLDER')"
        >
          <template v-if="pipelines.length" #count>
            <span class="text-body-main text-n-slate-11">
              {{ $t('CRM_PIPELINE.SETTINGS.COUNT', { n: pipelines.length }) }}
            </span>
          </template>
          <template #actions>
            <Button
              :label="$t('CRM_PIPELINE.SETTINGS.CREATE_PIPELINE')"
              size="sm"
              @click="openAddPopup"
            />
          </template>
        </BaseSettingsHeader>
      </template>

      <template #body>
        <BaseTable
          :headers="tableHeaders"
          :items="filteredRecords"
          :no-data-message="
            searchQuery
              ? $t('CRM_PIPELINE.SETTINGS.NO_RESULTS')
              : $t('CRM_PIPELINE.SETTINGS.LIST.EMPTY')
          "
        >
          <template #row="{ items }">
            <BaseTableRow
              v-for="pipeline in items"
              :key="pipeline.id"
              :item="pipeline"
            >
              <template #default>
                <BaseTableCell>
                  <span class="text-body-main text-n-slate-12">
                    {{ pipeline.name }}
                  </span>
                </BaseTableCell>

                <BaseTableCell>
                  <span class="text-body-main text-n-slate-11 line-clamp-2">
                    {{ pipeline.description || '—' }}
                  </span>
                </BaseTableCell>

                <BaseTableCell>
                  <span class="text-body-main text-n-slate-11">
                    {{ pipeline.stages?.length || 0 }}
                  </span>
                </BaseTableCell>

                <BaseTableCell align="end">
                  <div class="flex gap-3 justify-end flex-shrink-0">
                    <Button
                      v-tooltip.top="$t('CRM_PIPELINE.SETTINGS.EDIT')"
                      icon="i-woot-edit-pen"
                      slate
                      sm
                      :is-loading="loading[pipeline.id]"
                      @click="openEditPopup(pipeline)"
                    />
                    <Button
                      v-tooltip.top="
                        $t('CRM_PIPELINE.SETTINGS.DELETE_PIPELINE')
                      "
                      icon="i-woot-bin"
                      slate
                      sm
                      class="hover:enabled:text-n-ruby-11 hover:enabled:bg-n-ruby-2"
                      :is-loading="loading[pipeline.id]"
                      @click="openDeletePopup(pipeline)"
                    />
                  </div>
                </BaseTableCell>
              </template>
            </BaseTableRow>
          </template>
        </BaseTable>
      </template>

      <woot-modal v-model:show="showAddPopup" :on-close="hideAddPopup">
        <woot-modal-header
          :header-title="$t('CRM_PIPELINE.SETTINGS.CREATE_PIPELINE')"
        />
        <form
          class="flex flex-col items-start w-full"
          @submit.prevent="savePipeline"
        >
          <CrmPipelineFormField
            :label="$t('CRM_PIPELINE.SETTINGS.PIPELINE_NAME')"
          >
            <input v-model="pipelineForm.name" type="text" required />
          </CrmPipelineFormField>
          <CrmPipelineFormField
            :label="$t('CRM_PIPELINE.SETTINGS.PIPELINE_DESCRIPTION')"
          >
            <textarea v-model="pipelineForm.description" rows="2" />
          </CrmPipelineFormField>
          <div class="flex justify-end w-full gap-2 px-0 py-2">
            <Button
              faded
              slate
              type="button"
              :label="$t('CRM_PIPELINE.ACTIONS.CANCEL')"
              @click="hideAddPopup"
            />
            <Button
              type="submit"
              :label="$t('CRM_PIPELINE.ACTIONS.SAVE')"
              :is-loading="uiFlags.isSaving"
            />
          </div>
        </form>
      </woot-modal>

      <PipelineEditModal
        :show="showEditPopup"
        :pipeline="selectedPipeline"
        @close="hideEditPopup"
        @saved="onPipelineSaved"
      />

      <woot-delete-modal
        v-model:show="showDeleteConfirmationPopup"
        :on-close="closeDeletePopup"
        :on-confirm="confirmDeletion"
        :title="$t('CRM_PIPELINE.SETTINGS.DELETE_PIPELINE')"
        :message="$t('CRM_PIPELINE.SETTINGS.DELETE_PIPELINE_CONFIRM')"
        :message-value="deleteMessage"
        :confirm-text="$t('CRM_PIPELINE.SETTINGS.DELETE')"
        :reject-text="$t('CRM_PIPELINE.ACTIONS.CANCEL')"
      />
    </SettingsLayout>
  </div>
</template>
