<script setup>
import { computed, inject } from 'vue';
import { useI18n } from 'vue-i18n';
import { Handle, Position } from '@vue-flow/core';
import {
  askHandleId,
  conditionHandleId,
  NEXT_HANDLE,
  webhookHandleId,
} from '../../constants/conditionConfig';

const props = defineProps({
  data: {
    type: Object,
    required: true,
  },
  selected: {
    type: Boolean,
    default: false,
  },
});
const canvas = inject('wlBotFlowCanvas', null);
const { t } = useI18n();

const actionLabel = type => {
  const keys = {
    send_message: 'WL_BOT_FLOWS.ACTION_TYPES.SEND_MESSAGE',
    wait_for_contact_message: 'WL_BOT_FLOWS.ACTION_TYPES.WAIT_MESSAGE',
    wait_seconds: 'WL_BOT_FLOWS.ACTION_TYPES.WAIT_SECONDS',
    ask: 'WL_BOT_FLOWS.ACTION_TYPES.ASK',
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

const regularActions = computed(() =>
  (props.data.group.actions || []).filter(
    a =>
      a.type !== 'condition' &&
      a.type !== 'ask' &&
      !(a.type === 'send_webhook' && a.data?.wait_response)
  )
);

const conditionActions = computed(() =>
  (props.data.group.actions || []).filter(a => a.type === 'condition')
);

const askActions = computed(() =>
  (props.data.group.actions || []).filter(a => a.type === 'ask')
);

const webhookBranchActions = computed(() =>
  (props.data.group.actions || []).filter(
    a => a.type === 'send_webhook' && a.data?.wait_response
  )
);

const isEntryGroup = computed(
  () => canvas?.entryGroupId?.value === props.data.group.id
);

const nextGroupLabel = computed(() => {
  const nextId = props.data.group.next_group_id;
  if (!nextId) return t('WL_BOT_FLOWS.EDITOR.END_FLOW');
  const target = (canvas?.flowGroups?.value || []).find(g => g.id === nextId);
  return target?.name || nextId;
});

const onSelectGroup = () => canvas?.onSelectGroup(props.data.group);
const onSelectAction = action =>
  canvas?.onSelectAction({ group: props.data.group, action });
</script>

<template>
  <div
    class="min-w-[240px] rounded-lg border bg-n-solid-2 shadow-md"
    :class="selected ? 'border-n-brand' : 'border-n-weak'"
    @click.stop="onSelectGroup"
  >
    <Handle
      id="target"
      type="target"
      :position="Position.Left"
      class="!w-3 !h-3 !bg-n-brand !border-2 !border-n-solid-2 !z-10"
    />
    <div
      class="px-3 py-2 border-b border-n-weak font-medium text-n-slate-12 text-sm cursor-grab active:cursor-grabbing flex items-center gap-2"
    >
      <span
        v-if="isEntryGroup"
        class="shrink-0 px-1.5 py-0.5 text-[10px] font-semibold uppercase rounded bg-n-brand text-white"
      >
        {{ $t('WL_BOT_FLOWS.EDITOR.START_BADGE') }}
      </span>
      <span class="truncate">{{ data.group.name }}</span>
    </div>
    <ul class="divide-y divide-n-weak nodrag">
      <li
        v-for="act in regularActions"
        :key="act.id"
        class="px-3 py-2 text-xs text-n-slate-11 cursor-pointer hover:bg-n-alpha-2"
        @click.stop="onSelectAction(act)"
      >
        {{ actionLabel(act.type) }}
      </li>
    </ul>

    <!-- Condition branches -->
    <div
      v-for="condAction in conditionActions"
      :key="condAction.id"
      class="border-t border-n-weak nodrag"
    >
      <div
        class="px-3 py-2 text-xs font-medium text-n-slate-12 cursor-pointer hover:bg-n-alpha-2"
        @click.stop="onSelectAction(condAction)"
      >
        {{ actionLabel('condition') }}
      </div>
      <div
        v-for="rule in condAction.data?.rules || []"
        :key="rule.id"
        class="relative flex items-center justify-between pl-3 pr-6 py-2 text-xs text-n-slate-11 border-t border-n-weak/50"
      >
        <span class="truncate">{{ rule.label }}</span>
        <Handle
          :id="conditionHandleId(condAction.id, rule.id)"
          type="source"
          :position="Position.Right"
          class="!w-3 !h-3 !bg-n-brand !border-2 !border-n-solid-2 !z-10"
        />
      </div>
      <div
        class="relative flex items-center justify-between pl-3 pr-6 py-2 text-xs text-n-slate-11 border-t border-n-weak/50"
      >
        <span class="truncate">
          {{
            condAction.data?.fallback_label ||
            $t('WL_BOT_FLOWS.CONDITION.FALLBACK_LABEL')
          }}
        </span>
        <Handle
          :id="conditionHandleId(condAction.id, 'fallback')"
          type="source"
          :position="Position.Right"
          class="!w-3 !h-3 !bg-n-ruby-9 !border-2 !border-n-solid-2 !z-10"
        />
      </div>
    </div>

    <!-- Ask branches -->
    <div
      v-for="askAction in askActions"
      :key="askAction.id"
      class="border-t border-n-weak nodrag"
    >
      <div
        class="px-3 py-2 text-xs font-medium text-n-slate-12 cursor-pointer hover:bg-n-alpha-2"
        @click.stop="onSelectAction(askAction)"
      >
        {{ actionLabel('ask') }}
      </div>
      <div
        v-for="opt in askAction.data?.options || []"
        :key="opt.id"
        class="relative flex items-center justify-between pl-3 pr-6 py-2 text-xs text-n-slate-11 border-t border-n-weak/50"
      >
        <span class="truncate">{{ opt.label }}</span>
        <Handle
          :id="askHandleId(askAction.id, opt.id)"
          type="source"
          :position="Position.Right"
          class="!w-3 !h-3 !bg-n-brand !border-2 !border-n-solid-2 !z-10"
        />
      </div>
      <div
        class="relative flex items-center justify-between pl-3 pr-6 py-2 text-xs text-n-slate-11 border-t border-n-weak/50"
      >
        <span class="truncate">{{
          $t('WL_BOT_FLOWS.ASK.TIMEOUT_BRANCH')
        }}</span>
        <Handle
          :id="askHandleId(askAction.id, 'timeout')"
          type="source"
          :position="Position.Right"
          class="!w-3 !h-3 !bg-n-amber-9 !border-2 !border-n-solid-2 !z-10"
        />
      </div>
      <div
        v-if="askAction.data?.subtype !== 'text'"
        class="relative flex items-center justify-between pl-3 pr-6 py-2 text-xs text-n-slate-11 border-t border-n-weak/50"
      >
        <span class="truncate">{{
          $t('WL_BOT_FLOWS.ASK.INVALID_BRANCH')
        }}</span>
        <Handle
          :id="askHandleId(askAction.id, 'invalid')"
          type="source"
          :position="Position.Right"
          class="!w-3 !h-3 !bg-n-ruby-9 !border-2 !border-n-solid-2 !z-10"
        />
      </div>
    </div>

    <!-- Webhook sync branches -->
    <div
      v-for="wAction in webhookBranchActions"
      :key="wAction.id"
      class="border-t border-n-weak nodrag"
    >
      <div
        class="px-3 py-2 text-xs font-medium text-n-slate-12 cursor-pointer hover:bg-n-alpha-2"
        @click.stop="onSelectAction(wAction)"
      >
        {{ actionLabel('send_webhook') }}
      </div>
      <div
        class="relative flex items-center justify-between pl-3 pr-6 py-2 text-xs text-n-slate-11 border-t border-n-weak/50"
      >
        <span class="truncate">{{
          $t('WL_BOT_FLOWS.WEBHOOK.SUCCESS_BRANCH')
        }}</span>
        <Handle
          :id="webhookHandleId(wAction.id, 'success')"
          type="source"
          :position="Position.Right"
          class="!w-3 !h-3 !bg-n-teal-9 !border-2 !border-n-solid-2 !z-10"
        />
      </div>
      <div
        class="relative flex items-center justify-between pl-3 pr-6 py-2 text-xs text-n-slate-11 border-t border-n-weak/50"
      >
        <span class="truncate">{{
          $t('WL_BOT_FLOWS.WEBHOOK.FAILURE_BRANCH')
        }}</span>
        <Handle
          :id="webhookHandleId(wAction.id, 'failure')"
          type="source"
          :position="Position.Right"
          class="!w-3 !h-3 !bg-n-ruby-9 !border-2 !border-n-solid-2 !z-10"
        />
      </div>
    </div>

    <div
      class="relative flex items-center justify-between pl-3 pr-6 py-2 text-xs text-n-slate-11 border-t border-n-weak nodrag"
    >
      <span class="truncate">
        {{ $t('WL_BOT_FLOWS.EDITOR.THEN') }}: {{ nextGroupLabel }}
      </span>
      <Handle
        :id="NEXT_HANDLE"
        type="source"
        :position="Position.Right"
        class="!w-3 !h-3 !bg-n-slate-9 !border-2 !border-n-solid-2 !z-10"
      />
    </div>
  </div>
</template>
