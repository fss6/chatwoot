<script setup>
import { ref, computed, onMounted } from 'vue';
import { useStore } from 'dashboard/composables/store';
import { useI18n } from 'vue-i18n';
import CrmPipelinePageLayout from 'dashboard/components/crm-pipeline/CrmPipelinePageLayout.vue';
import CrmPipelineTaskModal from 'dashboard/components/crm-pipeline/CrmPipelineTaskModal.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import {
  BaseTable,
  BaseTableRow,
  BaseTableCell,
} from 'dashboard/components-next/table';

const store = useStore();
const { t } = useI18n();

const activeTab = ref('today');
const showCreateModal = ref(false);

const tabs = [
  { key: 'today', params: { today: true } },
  { key: 'overdue', params: { overdue: true } },
  { key: 'upcoming', params: { upcoming: true } },
  { key: 'done', params: { status: 'done' } },
  { key: 'all', params: {} },
];

const tasks = computed(() => store.getters['crmPipeline/getTasks']);
const deals = computed(() => store.getters['crmPipeline/getDeals']);
const agents = computed(() => store.getters['agents/getAgents'] || []);
const uiFlags = computed(() => store.getters['crmPipeline/getUIFlags']);

const activeListParams = computed(() => {
  const tab = tabs.find(item => item.key === activeTab.value);
  return tab?.params || {};
});

const tableHeaders = computed(() => [
  t('CRM_PIPELINE.TASKS.LIST.TABLE_HEADER.TITLE'),
  t('CRM_PIPELINE.TASKS.LIST.TABLE_HEADER.TYPE'),
  t('CRM_PIPELINE.TASKS.LIST.TABLE_HEADER.DUE'),
  t('CRM_PIPELINE.TASKS.LIST.TABLE_HEADER.ACTION'),
]);

const taskTypeLabel = type => `CRM_PIPELINE.TASKS.TYPES.${type}`;
const priorityLabel = priority => `CRM_PIPELINE.TASKS.PRIORITIES.${priority}`;

const loadTasks = () => {
  store.dispatch('crmPipeline/fetchTasks', activeListParams.value);
};

const setTab = key => {
  activeTab.value = key;
  loadTasks();
};

const completeTask = async task => {
  await store.dispatch('crmPipeline/completeTask', {
    id: task.id,
    listParams: activeListParams.value,
  });
};

const formatDueAt = dueAt => {
  if (!dueAt) return '—';
  return new Date(dueAt).toLocaleString();
};

onMounted(async () => {
  store.dispatch('agents/get');
  await store.dispatch('crmPipeline/fetchPipelines');
  const pipeline = store.getters['crmPipeline/getSelectedPipeline'];
  if (pipeline) {
    await store.dispatch('crmPipeline/fetchDeals', {
      pipeline_id: pipeline.id,
    });
  }
  loadTasks();
});
</script>

<template>
  <CrmPipelinePageLayout
    :title="$t('CRM_PIPELINE.TASKS.TITLE')"
    :description="$t('CRM_PIPELINE.TASKS.SUBTITLE')"
  >
    <template #actions>
      <Button
        sm
        :label="$t('CRM_PIPELINE.TASKS.CREATE')"
        @click="showCreateModal = true"
      />
    </template>

    <template #toolbar>
      <div class="flex gap-1 border-b border-n-weak w-full">
        <button
          v-for="tab in tabs"
          :key="tab.key"
          type="button"
          class="px-3 py-2 text-sm border-b-2 -mb-px transition-colors"
          :class="
            activeTab === tab.key
              ? 'border-n-brand text-n-brand font-medium'
              : 'border-transparent text-n-slate-11 hover:text-n-slate-12'
          "
          @click="setTab(tab.key)"
        >
          {{ $t(`CRM_PIPELINE.TASKS.TABS.${tab.key.toUpperCase()}`) }}
        </button>
      </div>
    </template>

    <div
      v-if="uiFlags.isFetchingTasks"
      class="py-20 text-center text-body-main text-n-slate-11"
    >
      {{ $t('CRM_PIPELINE.LOADING') }}
    </div>

    <BaseTable
      v-else
      :headers="tableHeaders"
      :items="tasks"
      :no-data-message="$t('CRM_PIPELINE.TASKS.EMPTY')"
    >
      <template #row="{ items }">
        <BaseTableRow v-for="task in items" :key="task.id" :item="task">
          <template #default>
            <BaseTableCell>
              <div class="min-w-0">
                <p class="text-body-main text-n-slate-12">{{ task.title }}</p>
                <p class="text-xs text-n-slate-11 mt-0.5">
                  {{ $t(priorityLabel(task.priority)) }}
                  <span v-if="task.is_overdue" class="text-n-ruby-11">
                    · {{ $t('CRM_PIPELINE.TASKS.OVERDUE') }}
                  </span>
                </p>
              </div>
            </BaseTableCell>

            <BaseTableCell>
              <span class="text-body-main text-n-slate-11">
                {{ $t(taskTypeLabel(task.task_type)) }}
              </span>
            </BaseTableCell>

            <BaseTableCell>
              <span class="text-body-main text-n-slate-11">
                {{ formatDueAt(task.due_at) }}
              </span>
            </BaseTableCell>

            <BaseTableCell align="end">
              <Button
                v-if="task.status === 'pending'"
                sm
                faded
                :label="$t('CRM_PIPELINE.TASKS.COMPLETE')"
                @click="completeTask(task)"
              />
            </BaseTableCell>
          </template>
        </BaseTableRow>
      </template>
    </BaseTable>

    <CrmPipelineTaskModal
      :show="showCreateModal"
      :agents="agents"
      :deals="deals"
      :list-params="activeListParams"
      @close="showCreateModal = false"
      @created="loadTasks"
    />
  </CrmPipelinePageLayout>
</template>
