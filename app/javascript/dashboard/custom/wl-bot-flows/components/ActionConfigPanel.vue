<script setup>
import { computed, ref, nextTick } from 'vue';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import Button from 'dashboard/components-next/button/Button.vue';
import ConditionEditorModal from './ConditionEditorModal.vue';
import {
  removeEdgesForAction,
  removeGroupFromFlow,
  summarizeRule,
} from '../constants/conditionConfig';

const props = defineProps({
  selection: {
    type: Object,
    default: null,
  },
  flowJson: {
    type: Object,
    required: true,
  },
});

const emit = defineEmits(['update:selection']);

const { t } = useI18n();
const showConditionModal = ref(false);
const conditionModalRef = ref(null);

const action = computed(() => props.selection?.action);
const group = computed(() => props.selection?.group);
const canRemoveGroup = computed(() => (props.flowJson.groups || []).length > 1);

const updateFlowJson = (groups, edges = props.flowJson.edges) => {
  emit('update:selection', {
    flowJson: { ...props.flowJson, groups, edges },
  });
};

const removeAction = () => {
  if (!action.value || !group.value) return;

  const actionId = action.value.id;
  const groupId = group.value.id;

  const groups = props.flowJson.groups.map(g => {
    if (g.id !== groupId) return g;
    return {
      ...g,
      actions: (g.actions || []).filter(a => a.id !== actionId),
    };
  });

  const edges = removeEdgesForAction(props.flowJson.edges, groupId, actionId);

  const updatedGroup = groups.find(g => g.id === groupId);

  emit('update:selection', {
    flowJson: { ...props.flowJson, groups, edges },
    selection: updatedGroup ? { group: updatedGroup, action: null } : null,
  });
  showConditionModal.value = false;
};

const updateActionData = (key, value) => {
  if (!action.value || !group.value) return;
  const groups = props.flowJson.groups.map(g => {
    if (g.id !== group.value.id) return g;
    return {
      ...g,
      actions: g.actions.map(a => {
        if (a.id !== action.value.id) return a;
        return { ...a, data: { ...a.data, [key]: value } };
      }),
    };
  });
  updateFlowJson(groups);
};

const updateGroupName = name => {
  if (!group.value) return;
  const groups = props.flowJson.groups.map(g =>
    g.id === group.value.id ? { ...g, name } : g
  );
  updateFlowJson(groups);
};

const updateGroupNext = nextGroupId => {
  if (!group.value) return;
  const groups = props.flowJson.groups.map(g =>
    g.id === group.value.id ? { ...g, next_group_id: nextGroupId } : g
  );
  updateFlowJson(groups);
};

const otherGroups = computed(() =>
  (props.flowJson.groups || []).filter(g => g.id !== group.value?.id)
);

const removeGroup = () => {
  if (!group.value) return;
  if (!canRemoveGroup.value) {
    useAlert(t('WL_BOT_FLOWS.EDITOR.CANNOT_REMOVE_LAST_GROUP'));
    return;
  }

  const flowJson = removeGroupFromFlow(props.flowJson, group.value.id);

  emit('update:selection', {
    flowJson,
    selection: null,
  });
};

const openConditionModal = async () => {
  showConditionModal.value = true;
  await nextTick();
  conditionModalRef.value?.open();
};

const onConditionSave = data => {
  if (!action.value || !group.value) return;
  const groups = props.flowJson.groups.map(g => {
    if (g.id !== group.value.id) return g;
    return {
      ...g,
      actions: g.actions.map(a => {
        if (a.id !== action.value.id) return a;
        return { ...a, data };
      }),
    };
  });
  updateFlowJson(groups);
  showConditionModal.value = false;
};

const conditionSummaries = computed(() => {
  const data = action.value?.data;
  if (!data?.rules?.length) return [];
  return data.rules.map(rule => summarizeRule(rule, t));
});

const groupNameById = id =>
  props.flowJson.groups.find(g => g.id === id)?.name || id;

const actionTypeLabel = type => {
  const keys = {
    send_message: 'WL_BOT_FLOWS.ACTION_TYPES.SEND_MESSAGE',
    wait_for_contact_message: 'WL_BOT_FLOWS.ACTION_TYPES.WAIT_MESSAGE',
    wait_seconds: 'WL_BOT_FLOWS.ACTION_TYPES.WAIT_SECONDS',
    condition: 'WL_BOT_FLOWS.ACTION_TYPES.CONDITION',
    go_to_group: 'WL_BOT_FLOWS.ACTION_TYPES.GO_TO_GROUP',
    transfer_to_team: 'WL_BOT_FLOWS.ACTION_TYPES.TRANSFER_TEAM',
    assign_agent: 'WL_BOT_FLOWS.ACTION_TYPES.ASSIGN_AGENT',
    finish_conversation: 'WL_BOT_FLOWS.ACTION_TYPES.FINISH',
    add_label: 'WL_BOT_FLOWS.ACTION_TYPES.ADD_LABEL',
    remove_label: 'WL_BOT_FLOWS.ACTION_TYPES.REMOVE_LABEL',
    set_custom_attribute: 'WL_BOT_FLOWS.ACTION_TYPES.SET_ATTRIBUTE',
    send_webhook: 'WL_BOT_FLOWS.ACTION_TYPES.WEBHOOK',
  };
  return keys[type] ? t(keys[type]) : type;
};
</script>

<template>
  <div v-if="group && !action" class="flex flex-col gap-3 p-4">
    <div class="flex items-center justify-between gap-2">
      <p class="text-sm font-medium text-n-slate-12">
        {{ $t('WL_BOT_FLOWS.FORM.GROUP_NAME') }}
      </p>
      <Button
        ghost
        xs
        color="ruby"
        :label="$t('WL_BOT_FLOWS.EDITOR.REMOVE_GROUP')"
        :disabled="!canRemoveGroup"
        @click="removeGroup"
      />
    </div>
    <input
      :value="group.name"
      class="px-3 py-2 text-sm border rounded-lg border-n-weak bg-n-solid-2 text-n-slate-12"
      @input="updateGroupName($event.target.value)"
    />
    <label class="text-xs text-n-slate-11">{{
      $t('WL_BOT_FLOWS.EDITOR.NEXT_GROUP')
    }}</label>
    <select
      :value="group.next_group_id || ''"
      class="px-3 py-2 text-sm border rounded-lg border-n-weak bg-n-solid-2 text-n-slate-12"
      @change="updateGroupNext($event.target.value)"
    >
      <option value="">{{ $t('WL_BOT_FLOWS.EDITOR.END_FLOW') }}</option>
      <option v-for="g in otherGroups" :key="g.id" :value="g.id">
        {{ g.name }}
      </option>
    </select>
    <p v-if="!canRemoveGroup" class="text-xs text-n-slate-11">
      {{ $t('WL_BOT_FLOWS.EDITOR.CANNOT_REMOVE_LAST_GROUP') }}
    </p>
  </div>
  <div v-else-if="action" class="flex flex-col gap-3 p-4">
    <div class="flex items-center justify-between gap-2">
      <p class="text-sm font-medium text-n-slate-12">
        {{ actionTypeLabel(action.type) }}
      </p>
      <Button
        ghost
        xs
        color="ruby"
        :label="$t('WL_BOT_FLOWS.EDITOR.REMOVE_ACTION')"
        @click="removeAction"
      />
    </div>
    <template v-if="action.type === 'send_message'">
      <label class="text-xs text-n-slate-11">{{
        $t('WL_BOT_FLOWS.FORM.MESSAGE_TEXT')
      }}</label>
      <textarea
        :value="action.data?.text"
        rows="4"
        class="px-3 py-2 text-sm border rounded-lg border-n-weak bg-n-solid-2 text-n-slate-12"
        @input="updateActionData('text', $event.target.value)"
      />
    </template>
    <template v-else-if="action.type === 'wait_for_contact_message'">
      <label class="text-xs text-n-slate-11">{{
        $t('WL_BOT_FLOWS.FORM.SAVE_AS')
      }}</label>
      <input
        :value="action.data?.save_as"
        class="px-3 py-2 text-sm border rounded-lg border-n-weak bg-n-solid-2 text-n-slate-12"
        @input="updateActionData('save_as', $event.target.value)"
      />
    </template>
    <template v-else-if="action.type === 'wait_seconds'">
      <label class="text-xs text-n-slate-11">{{
        $t('WL_BOT_FLOWS.FORM.SECONDS')
      }}</label>
      <input
        type="number"
        :value="action.data?.seconds"
        class="px-3 py-2 text-sm border rounded-lg border-n-weak bg-n-solid-2 text-n-slate-12"
        @input="updateActionData('seconds', Number($event.target.value))"
      />
    </template>
    <template v-else-if="action.type === 'condition'">
      <p class="text-xs text-n-slate-11">
        {{ $t('WL_BOT_FLOWS.CONDITION.PANEL_HINT') }}
      </p>
      <Button
        sm
        :label="$t('WL_BOT_FLOWS.CONDITION.EDIT')"
        @click="openConditionModal"
      />
      <ul
        v-if="conditionSummaries.length"
        class="space-y-2 text-xs text-n-slate-11"
      >
        <li
          v-for="(summary, index) in conditionSummaries"
          :key="index"
          class="p-2 rounded bg-n-alpha-2"
        >
          {{ summary }}
          <span
            v-if="action.data?.rules?.[index]?.target_group_id"
            class="block mt-1 text-n-slate-12"
          >
            {{ $t('WL_BOT_FLOWS.EDITOR.GOES_TO') }}
            {{ groupNameById(action.data.rules[index].target_group_id) }}
          </span>
        </li>
      </ul>
      <p
        v-if="action.data?.fallback_group_id"
        class="text-xs text-n-slate-11 p-2 rounded bg-n-alpha-2"
      >
        {{
          action.data.fallback_label ||
          $t('WL_BOT_FLOWS.CONDITION.FALLBACK_LABEL')
        }}
        {{ $t('WL_BOT_FLOWS.EDITOR.GOES_TO') }}
        {{ groupNameById(action.data.fallback_group_id) }}
      </p>
      <ConditionEditorModal
        v-if="showConditionModal"
        ref="conditionModalRef"
        :action="action"
        :groups="flowJson.groups"
        @save="onConditionSave"
        @close="showConditionModal = false"
      />
    </template>
    <template v-else-if="action.type === 'go_to_group'">
      <label class="text-xs text-n-slate-11">{{
        $t('WL_BOT_FLOWS.FORM.TARGET_GROUP')
      }}</label>
      <select
        :value="action.data?.target_group_id"
        class="px-3 py-2 text-sm border rounded-lg border-n-weak bg-n-solid-2 text-n-slate-12"
        @change="updateActionData('target_group_id', $event.target.value)"
      >
        <option value="">
          {{ $t('WL_BOT_FLOWS.CONDITION.SELECT_GROUP') }}
        </option>
        <option v-for="g in flowJson.groups" :key="g.id" :value="g.id">
          {{ g.name }}
        </option>
      </select>
    </template>
    <template v-else-if="action.type === 'transfer_to_team'">
      <label class="text-xs text-n-slate-11">{{
        $t('WL_BOT_FLOWS.FORM.TEAM_ID')
      }}</label>
      <input
        :value="action.data?.team_id"
        class="px-3 py-2 text-sm border rounded-lg border-n-weak bg-n-solid-2 text-n-slate-12"
        @input="updateActionData('team_id', $event.target.value)"
      />
    </template>
    <template v-else-if="action.type === 'assign_agent'">
      <label class="text-xs text-n-slate-11">{{
        $t('WL_BOT_FLOWS.FORM.AGENT_ID')
      }}</label>
      <input
        :value="action.data?.agent_id"
        class="px-3 py-2 text-sm border rounded-lg border-n-weak bg-n-solid-2 text-n-slate-12"
        @input="updateActionData('agent_id', $event.target.value)"
      />
    </template>
    <template
      v-else-if="action.type === 'add_label' || action.type === 'remove_label'"
    >
      <label class="text-xs text-n-slate-11">{{
        $t('WL_BOT_FLOWS.FORM.LABELS')
      }}</label>
      <input
        :value="(action.data?.labels || []).join(', ')"
        class="px-3 py-2 text-sm border rounded-lg border-n-weak bg-n-solid-2 text-n-slate-12"
        @input="
          updateActionData(
            'labels',
            $event.target.value
              .split(',')
              .map(s => s.trim())
              .filter(Boolean)
          )
        "
      />
    </template>
    <template v-else-if="action.type === 'ask'">
      <label class="text-xs text-n-slate-11">{{
        $t('WL_BOT_FLOWS.FORM.MESSAGE_TEXT')
      }}</label>
      <textarea
        :value="action.data?.text"
        rows="3"
        class="px-3 py-2 text-sm border rounded-lg border-n-weak bg-n-solid-2 text-n-slate-12"
        @input="updateActionData('text', $event.target.value)"
      />
      <label class="text-xs text-n-slate-11">{{
        $t('WL_BOT_FLOWS.FORM.ASK_SUBTYPE')
      }}</label>
      <select
        :value="action.data?.subtype || 'text'"
        class="px-3 py-2 text-sm border rounded-lg border-n-weak bg-n-solid-2 text-n-slate-12"
        @change="updateActionData('subtype', $event.target.value)"
      >
        <option value="text">{{ $t('WL_BOT_FLOWS.ASK.SUBTYPE_TEXT') }}</option>
        <option value="buttons">
          {{ $t('WL_BOT_FLOWS.ASK.SUBTYPE_BUTTONS') }}
        </option>
        <option value="list">{{ $t('WL_BOT_FLOWS.ASK.SUBTYPE_LIST') }}</option>
      </select>
      <template v-if="action.data?.subtype && action.data.subtype !== 'text'">
        <label class="text-xs text-n-slate-11">{{
          $t('WL_BOT_FLOWS.FORM.ASK_OPTIONS')
        }}</label>
        <div
          v-for="(opt, idx) in action.data?.options || []"
          :key="opt.id"
          class="flex items-center gap-2"
        >
          <input
            :value="opt.label"
            class="flex-1 px-2 py-1 text-xs border rounded border-n-weak bg-n-solid-2 text-n-slate-12"
            :placeholder="$t('WL_BOT_FLOWS.ASK.OPTION_LABEL')"
            @input="
              updateActionData(
                'options',
                (action.data.options || []).map((o, i) =>
                  i === idx ? { ...o, label: $event.target.value } : o
                )
              )
            "
          />
          <Button
            ghost
            xs
            color="ruby"
            label="×"
            @click="
              updateActionData(
                'options',
                (action.data.options || []).filter((_, i) => i !== idx)
              )
            "
          />
        </div>
        <Button
          ghost
          xs
          :label="$t('WL_BOT_FLOWS.ASK.ADD_OPTION')"
          @click="
            updateActionData('options', [
              ...(action.data?.options || []),
              { id: `opt_${Date.now()}`, label: '', target_group_id: '' },
            ])
          "
        />
        <label class="text-xs text-n-slate-11 mt-2">{{
          $t('WL_BOT_FLOWS.FORM.INVALID_GROUP')
        }}</label>
        <select
          :value="action.data?.invalid_response_group_id || ''"
          class="px-3 py-2 text-sm border rounded-lg border-n-weak bg-n-solid-2 text-n-slate-12"
          @change="
            updateActionData('invalid_response_group_id', $event.target.value)
          "
        >
          <option value="">
            {{ $t('WL_BOT_FLOWS.CONDITION.SELECT_GROUP') }}
          </option>
          <option v-for="g in flowJson.groups" :key="g.id" :value="g.id">
            {{ g.name }}
          </option>
        </select>
      </template>
      <label class="text-xs text-n-slate-11">{{
        $t('WL_BOT_FLOWS.FORM.SAVE_AS')
      }}</label>
      <input
        :value="action.data?.save_as"
        class="px-3 py-2 text-sm border rounded-lg border-n-weak bg-n-solid-2 text-n-slate-12"
        @input="updateActionData('save_as', $event.target.value)"
      />
      <label class="text-xs text-n-slate-11">{{
        $t('WL_BOT_FLOWS.FORM.TIMEOUT_SECONDS')
      }}</label>
      <input
        type="number"
        :value="action.data?.timeout || 300"
        class="px-3 py-2 text-sm border rounded-lg border-n-weak bg-n-solid-2 text-n-slate-12"
        @input="updateActionData('timeout', Number($event.target.value))"
      />
      <label class="text-xs text-n-slate-11">{{
        $t('WL_BOT_FLOWS.FORM.TIMEOUT_GROUP')
      }}</label>
      <select
        :value="action.data?.timeout_group_id || ''"
        class="px-3 py-2 text-sm border rounded-lg border-n-weak bg-n-solid-2 text-n-slate-12"
        @change="updateActionData('timeout_group_id', $event.target.value)"
      >
        <option value="">
          {{ $t('WL_BOT_FLOWS.CONDITION.SELECT_GROUP') }}
        </option>
        <option v-for="g in flowJson.groups" :key="g.id" :value="g.id">
          {{ g.name }}
        </option>
      </select>
    </template>
    <template v-else-if="action.type === 'send_webhook'">
      <label class="text-xs text-n-slate-11">{{
        $t('WL_BOT_FLOWS.FORM.WEBHOOK_URL')
      }}</label>
      <input
        :value="action.data?.url"
        class="px-3 py-2 text-sm border rounded-lg border-n-weak bg-n-solid-2 text-n-slate-12"
        @input="updateActionData('url', $event.target.value)"
      />
      <div class="flex items-center gap-2 mt-2">
        <input
          id="wait_response"
          type="checkbox"
          :checked="action.data?.wait_response"
          @change="updateActionData('wait_response', $event.target.checked)"
        />
        <label for="wait_response" class="text-xs text-n-slate-11">{{
          $t('WL_BOT_FLOWS.FORM.WAIT_RESPONSE')
        }}</label>
      </div>
      <template v-if="action.data?.wait_response">
        <label class="text-xs text-n-slate-11">{{
          $t('WL_BOT_FLOWS.FORM.WEBHOOK_TIMEOUT')
        }}</label>
        <input
          type="number"
          :value="action.data?.timeout_seconds || 20"
          class="px-3 py-2 text-sm border rounded-lg border-n-weak bg-n-solid-2 text-n-slate-12"
          @input="
            updateActionData('timeout_seconds', Number($event.target.value))
          "
        />
        <label class="text-xs text-n-slate-11">{{
          $t('WL_BOT_FLOWS.FORM.SUCCESS_GROUP')
        }}</label>
        <select
          :value="action.data?.success_group_id || ''"
          class="px-3 py-2 text-sm border rounded-lg border-n-weak bg-n-solid-2 text-n-slate-12"
          @change="updateActionData('success_group_id', $event.target.value)"
        >
          <option value="">
            {{ $t('WL_BOT_FLOWS.CONDITION.SELECT_GROUP') }}
          </option>
          <option v-for="g in flowJson.groups" :key="g.id" :value="g.id">
            {{ g.name }}
          </option>
        </select>
        <label class="text-xs text-n-slate-11">{{
          $t('WL_BOT_FLOWS.FORM.FAILURE_GROUP')
        }}</label>
        <select
          :value="action.data?.failure_group_id || ''"
          class="px-3 py-2 text-sm border rounded-lg border-n-weak bg-n-solid-2 text-n-slate-12"
          @change="updateActionData('failure_group_id', $event.target.value)"
        >
          <option value="">
            {{ $t('WL_BOT_FLOWS.CONDITION.SELECT_GROUP') }}
          </option>
          <option v-for="g in flowJson.groups" :key="g.id" :value="g.id">
            {{ g.name }}
          </option>
        </select>
      </template>
    </template>
  </div>
  <p v-else class="p-4 text-sm text-n-slate-11">
    {{ $t('WL_BOT_FLOWS.EDITOR.SELECT_ACTION') }}
  </p>
</template>
