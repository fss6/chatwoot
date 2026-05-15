<script setup>
import { ref, computed, onMounted } from 'vue';
import { useRoute, useRouter } from 'vue-router';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import wlBotFlows from 'dashboard/api/wlBotFlows/flows';
import ActionConfigPanel from '../components/ActionConfigPanel.vue';
import FlowCanvas from '../components/FlowCanvas.vue';
import {
  defaultConditionData,
  migrateFlowNextGroups,
} from '../constants/conditionConfig';
import Button from 'dashboard/components-next/button/Button.vue';

const { t } = useI18n();
const route = useRoute();
const router = useRouter();

const flow = ref(null);
const draftJson = ref(null);
const selection = ref(null);
const selectedGroupId = ref(null);
const isSaving = ref(false);

const flowId = computed(() => route.params.flowId);
const accountId = computed(() => route.params.accountId);

const ACTION_TYPES = [
  { type: 'send_message', labelKey: 'WL_BOT_FLOWS.ACTION_TYPES.SEND_MESSAGE' },
  { type: 'ask', labelKey: 'WL_BOT_FLOWS.ACTION_TYPES.ASK' },
  {
    type: 'wait_for_contact_message',
    labelKey: 'WL_BOT_FLOWS.ACTION_TYPES.WAIT_MESSAGE',
  },
  { type: 'wait_seconds', labelKey: 'WL_BOT_FLOWS.ACTION_TYPES.WAIT_SECONDS' },
  { type: 'condition', labelKey: 'WL_BOT_FLOWS.ACTION_TYPES.CONDITION' },
  { type: 'go_to_group', labelKey: 'WL_BOT_FLOWS.ACTION_TYPES.GO_TO_GROUP' },
  {
    type: 'transfer_to_team',
    labelKey: 'WL_BOT_FLOWS.ACTION_TYPES.TRANSFER_TEAM',
  },
  { type: 'assign_agent', labelKey: 'WL_BOT_FLOWS.ACTION_TYPES.ASSIGN_AGENT' },
  { type: 'finish_conversation', labelKey: 'WL_BOT_FLOWS.ACTION_TYPES.FINISH' },
  { type: 'add_label', labelKey: 'WL_BOT_FLOWS.ACTION_TYPES.ADD_LABEL' },
  { type: 'remove_label', labelKey: 'WL_BOT_FLOWS.ACTION_TYPES.REMOVE_LABEL' },
  {
    type: 'set_custom_attribute',
    labelKey: 'WL_BOT_FLOWS.ACTION_TYPES.SET_ATTRIBUTE',
  },
  { type: 'send_webhook', labelKey: 'WL_BOT_FLOWS.ACTION_TYPES.WEBHOOK' },
];

const defaultDataFor = type => {
  const map = {
    send_message: { text: '' },
    ask: {
      text: '',
      subtype: 'text',
      options: [],
      save_as: 'response',
      timeout: 300,
      timeout_group_id: '',
      invalid_response_group_id: '',
    },
    wait_for_contact_message: { save_as: 'response', timeout: 'default' },
    wait_seconds: { seconds: 3 },
    condition: defaultConditionData(),
    go_to_group: { target_group_id: '' },
    transfer_to_team: { team_id: '', message: '' },
    assign_agent: { agent_id: '', message: '' },
    finish_conversation: { message: '' },
    add_label: { labels: [] },
    remove_label: { labels: [] },
    set_custom_attribute: { target: 'contact', key: '', value: '' },
    send_webhook: { url: '', method: 'POST', body: {} },
  };
  return map[type] || {};
};

const ensureEntryGroup = () => {
  if (!draftJson.value) return;
  if (draftJson.value.entry_group_id) return;
  const first = draftJson.value.groups?.[0];
  if (first) draftJson.value.entry_group_id = first.id;
};

const loadFlow = async () => {
  const { data } = await wlBotFlows.show(flowId.value);
  flow.value = data;
  draftJson.value = migrateFlowNextGroups(
    JSON.parse(JSON.stringify(data.draft_json || {}))
  );
  if (!draftJson.value.groups) draftJson.value.groups = [];
  if (!draftJson.value.edges) draftJson.value.edges = [];
  ensureEntryGroup();
  if (draftJson.value.groups.length && !selectedGroupId.value) {
    selectedGroupId.value =
      draftJson.value.entry_group_id || draftJson.value.groups[0].id;
  }
};

const saveFlow = async () => {
  isSaving.value = true;
  try {
    const { data } = await wlBotFlows.update(flowId.value, {
      name: flow.value.name,
      inbox_id: flow.value.inbox_id,
      draft_json: draftJson.value,
    });
    flow.value = data;
    useAlert(t('WL_BOT_FLOWS.MESSAGES.SAVED'));
  } catch (e) {
    useAlert(e.response?.data?.error || t('WL_BOT_FLOWS.MESSAGES.ERROR'));
  } finally {
    isSaving.value = false;
  }
};

const publishFlow = async () => {
  await saveFlow();
  try {
    const { data } = await wlBotFlows.publish(flowId.value);
    flow.value = data;
    useAlert(t('WL_BOT_FLOWS.MESSAGES.PUBLISHED'));
  } catch (e) {
    useAlert(e.response?.data?.error || t('WL_BOT_FLOWS.MESSAGES.ERROR'));
  }
};

const addGroup = () => {
  const id = `group_${crypto.randomUUID().slice(0, 8)}`;
  const newGroup = {
    id,
    name: 'New group',
    position: { x: 200 + draftJson.value.groups.length * 40, y: 200 },
    actions: [],
  };
  draftJson.value = {
    ...draftJson.value,
    groups: [...draftJson.value.groups, newGroup],
  };
  ensureEntryGroup();
  selectedGroupId.value = id;
  selection.value = { group: newGroup, action: null };
};

const addActionToSelectedGroup = actionType => {
  const groupId =
    selectedGroupId.value ||
    draftJson.value.entry_group_id ||
    draftJson.value.groups?.[0]?.id;
  if (!groupId) return;

  const action = {
    id: `act_${crypto.randomUUID().slice(0, 8)}`,
    type: actionType,
    data: defaultDataFor(actionType),
  };

  let targetGroup = null;
  const groups = draftJson.value.groups.map(group => {
    if (group.id !== groupId) return group;
    targetGroup = {
      ...group,
      actions: [...(group.actions || []), action],
    };
    return targetGroup;
  });

  if (!targetGroup) return;

  draftJson.value = { ...draftJson.value, groups };
  selectedGroupId.value = groupId;
  selection.value = { group: targetGroup, action };
};

const onSelectGroup = group => {
  selectedGroupId.value = group.id;
  selection.value = { group, action: null };
};

const onSelectAction = ({ group, action }) => {
  selectedGroupId.value = group.id;
  selection.value = { group, action };
};

const onPanelUpdate = ({ flowJson: updated, selection: nextSelection }) => {
  if (!updated) return;
  draftJson.value = updated;
  if (nextSelection !== undefined) {
    selection.value = nextSelection;
    selectedGroupId.value = nextSelection?.group?.id || null;
    return;
  }
  if (selection.value?.group) {
    const group = updated.groups.find(g => g.id === selection.value.group.id);
    if (!group) {
      selection.value = null;
      return;
    }
    const action = selection.value.action
      ? group.actions?.find(a => a.id === selection.value.action.id)
      : null;
    selection.value = { group, action: action || null };
  }
};

const goBack = () => {
  router.push({
    name: 'wl_bot_flows_index',
    params: { accountId: accountId.value },
  });
};

const openLogs = () => {
  router.push({
    name: 'wl_bot_flow_logs',
    params: { accountId: accountId.value, flowId: flowId.value },
  });
};

onMounted(loadFlow);
</script>

<template>
  <div v-if="flow && draftJson" class="flex flex-col w-full h-full">
    <header
      class="flex items-center gap-3 px-4 py-3 border-b border-n-weak bg-n-solid-2 shrink-0"
    >
      <Button
        ghost
        xs
        :label="$t('WL_BOT_FLOWS.ACTIONS.BACK')"
        @click="goBack"
      />
      <input
        v-model="flow.name"
        class="flex-1 px-2 py-1 text-lg font-semibold bg-transparent border-none text-n-slate-12 focus:outline-none"
      />
      <span class="text-xs capitalize text-n-slate-11">{{ flow.status }}</span>
      <label class="flex items-center gap-2 text-xs text-n-slate-11">
        <span>{{ $t('WL_BOT_FLOWS.EDITOR.ENTRY_GROUP') }}</span>
        <select
          v-model="draftJson.entry_group_id"
          class="px-2 py-1 text-xs border rounded border-n-weak bg-n-solid-2 text-n-slate-12"
        >
          <option v-for="g in draftJson.groups" :key="g.id" :value="g.id">
            {{ g.name }}
          </option>
        </select>
      </label>
      <input
        v-model.number="flow.inbox_id"
        type="number"
        :placeholder="$t('WL_BOT_FLOWS.FORM.INBOX')"
        class="w-24 px-2 py-1 text-xs border rounded border-n-weak bg-n-solid-2 text-n-slate-12"
      />
      <Button
        ghost
        xs
        :label="$t('WL_BOT_FLOWS.ACTIONS.LOGS')"
        @click="openLogs"
      />
      <Button
        :label="$t('WL_BOT_FLOWS.ACTIONS.SAVE')"
        :is-loading="isSaving"
        @click="saveFlow"
      />
      <Button
        :label="$t('WL_BOT_FLOWS.ACTIONS.PUBLISH')"
        @click="publishFlow"
      />
    </header>

    <div class="flex flex-1 min-h-0">
      <aside
        class="w-52 shrink-0 border-r border-n-weak bg-n-solid-2 flex flex-col"
      >
        <div class="p-3 border-b border-n-weak">
          <Button
            xs
            class="w-full"
            :label="$t('WL_BOT_FLOWS.EDITOR.ADD_GROUP')"
            @click="addGroup"
          />
        </div>
        <p class="px-3 py-2 text-xs font-medium text-n-slate-11">
          {{ $t('WL_BOT_FLOWS.EDITOR.ACTIONS_TITLE') }}
        </p>
        <ul class="flex-1 overflow-auto px-2 pb-2">
          <li v-for="item in ACTION_TYPES" :key="item.type">
            <button
              type="button"
              class="w-full px-2 py-2 text-left text-xs rounded hover:bg-n-alpha-2 text-n-slate-12"
              @click="addActionToSelectedGroup(item.type)"
            >
              {{ $t(item.labelKey) }}
            </button>
          </li>
        </ul>
      </aside>

      <div class="flex-1 min-w-0 h-full min-h-0">
        <FlowCanvas
          :flow-json="draftJson"
          :selected-group-id="selectedGroupId"
          @update:flow-json="draftJson = $event"
          @select-group="onSelectGroup"
          @select-action="onSelectAction"
        />
      </div>

      <aside
        class="w-72 shrink-0 border-l border-n-weak bg-n-solid-2 overflow-auto"
      >
        <p
          class="px-3 py-2 text-xs font-medium text-n-slate-11 border-b border-n-weak"
        >
          {{ $t('WL_BOT_FLOWS.EDITOR.PROPERTIES') }}
        </p>
        <ActionConfigPanel
          :selection="selection"
          :flow-json="draftJson"
          @update:selection="onPanelUpdate"
        />
      </aside>
    </div>
  </div>
</template>
