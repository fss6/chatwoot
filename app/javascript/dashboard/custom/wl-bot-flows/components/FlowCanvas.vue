<script setup>
import { ref, watch, markRaw, provide, computed, nextTick } from 'vue';
import { VueFlow, addEdge } from '@vue-flow/core';
import { Background } from '@vue-flow/background';
import { Controls } from '@vue-flow/controls';
import { MiniMap } from '@vue-flow/minimap';
import BotGroupNode from './nodes/BotGroupNode.vue';
import {
  ASK_PREFIX,
  CONDITION_PREFIX,
  NEXT_HANDLE,
  WEBHOOK_PREFIX,
  applyAskConnection,
  applyConditionConnection,
  applyNextConnection,
  applyWebhookConnection,
  askEdgeId,
  clearAskConnection,
  clearConditionConnection,
  clearNextConnection,
  clearWebhookConnection,
  conditionEdgeId,
  isNextSourceHandle,
  mergeFlowEdges,
  migrateFlowNextGroups,
  nextEdgeId,
  parseAskHandleId,
  parseConditionHandleId,
  parseWebhookHandleId,
  sanitizeEdges,
  webhookEdgeId,
} from '../constants/conditionConfig';
import '@vue-flow/core/dist/style.css';
import '@vue-flow/core/dist/theme-default.css';
import '@vue-flow/controls/dist/style.css';
import '@vue-flow/minimap/dist/style.css';

const props = defineProps({
  flowJson: {
    type: Object,
    required: true,
  },
  selectedGroupId: {
    type: String,
    default: null,
  },
});

const emit = defineEmits(['update:flowJson', 'selectGroup', 'selectAction']);

const nodeTypes = { botGroup: markRaw(BotGroupNode) };

const nodes = ref([]);
const edges = ref([]);
let skipFlowSync = false;

const groupsSignature = groups =>
  JSON.stringify(
    (groups || []).map(g => ({
      id: g.id,
      name: g.name,
      next_group_id: g.next_group_id || '',
      actions: (g.actions || []).map(a => ({
        id: a.id,
        type: a.type,
        data: a.data,
      })),
    }))
  );

let lastGroupsSignature = '';

const applyEdges = groups => {
  edges.value = mergeFlowEdges(groups);
};

const syncFromFlow = json => {
  skipFlowSync = true;
  const migrated = migrateFlowNextGroups(json || {});
  const groups = migrated?.groups || [];

  nodes.value = groups.map(group => {
    const existing = nodes.value.find(n => n.id === group.id);
    return {
      id: group.id,
      type: 'botGroup',
      position: existing?.position || group.position || { x: 0, y: 0 },
      data: { group },
      selected: group.id === props.selectedGroupId,
    };
  });

  nextTick(() => {
    applyEdges(groups);
    nextTick(() => {
      skipFlowSync = false;
    });
  });
};

const refreshNodeData = groups => {
  nodes.value = groups.map(group => {
    const existing = nodes.value.find(n => n.id === group.id);
    return {
      id: group.id,
      type: 'botGroup',
      position: existing?.position || group.position || { x: 0, y: 0 },
      data: { group },
      selected: group.id === props.selectedGroupId,
    };
  });

  edges.value = mergeFlowEdges(groups);
};

watch(
  () => props.flowJson?.groups,
  groups => {
    if (skipFlowSync || !groups) return;

    const signature = groupsSignature(groups);
    if (signature !== lastGroupsSignature) {
      lastGroupsSignature = signature;
      syncFromFlow(props.flowJson);
      return;
    }

    refreshNodeData(groups);
  },
  { immediate: true, deep: true }
);

watch(
  () => props.selectedGroupId,
  id => {
    nodes.value = nodes.value.map(n => ({
      ...n,
      selected: n.id === id,
    }));
  }
);

const groupsWithPositions = baseGroups =>
  (baseGroups || []).map(group => {
    const node = nodes.value.find(n => n.id === group.id);
    return node ? { ...group, position: node.position } : group;
  });

const serializeEdges = () =>
  sanitizeEdges(edges.value, props.flowJson?.groups || [])
    .filter(e => e.sourceHandle?.startsWith(CONDITION_PREFIX))
    .map(e => ({
      id: e.id,
      source: e.source,
      target: e.target,
      ...(e.sourceHandle ? { sourceHandle: e.sourceHandle } : {}),
      ...(e.targetHandle ? { targetHandle: e.targetHandle } : {}),
    }));

const persistFlow = (
  flowJsonOverride = null,
  { rebuildEdges = false } = {}
) => {
  const base = flowJsonOverride || props.flowJson;
  skipFlowSync = true;
  const groups = groupsWithPositions(base.groups);
  const serializedEdges = serializeEdges();

  emit('update:flowJson', {
    ...base,
    groups,
    edges: serializedEdges,
  });

  nextTick(() => {
    if (rebuildEdges) {
      applyEdges(groups);
    }
    skipFlowSync = false;
  });
};

const onSelectGroup = group => emit('selectGroup', group);
const onSelectAction = payload => emit('selectAction', payload);

const entryGroupId = computed(() => props.flowJson?.entry_group_id);
const flowGroups = computed(() => props.flowJson?.groups || []);

provide('wlBotFlowCanvas', {
  onSelectGroup,
  onSelectAction,
  entryGroupId,
  flowGroups,
});

const isValidConnection = ({ source, target, sourceHandle }) => {
  if (source === target) return false;
  const groupIds = new Set((props.flowJson?.groups || []).map(g => g.id));
  if (!groupIds.has(source) || !groupIds.has(target)) return false;

  if (
    sourceHandle?.startsWith(CONDITION_PREFIX) ||
    sourceHandle?.startsWith(ASK_PREFIX) ||
    sourceHandle?.startsWith(WEBHOOK_PREFIX)
  )
    return true;

  if (!sourceHandle || isNextSourceHandle(sourceHandle)) return true;

  return false;
};

const applyBranchConnection = (flow, connection) => {
  const { sourceHandle, source, target } = connection;
  if (sourceHandle?.startsWith(CONDITION_PREFIX)) {
    return {
      flow: applyConditionConnection(flow, {
        sourceGroupId: source,
        sourceHandle,
        targetGroupId: target,
      }),
      edgeId: conditionEdgeId(
        source,
        parseConditionHandleId(sourceHandle).actionId,
        parseConditionHandleId(sourceHandle).branchId
      ),
    };
  }
  if (sourceHandle?.startsWith(ASK_PREFIX)) {
    return {
      flow: applyAskConnection(flow, {
        sourceGroupId: source,
        sourceHandle,
        targetGroupId: target,
      }),
      edgeId: askEdgeId(
        source,
        parseAskHandleId(sourceHandle).actionId,
        parseAskHandleId(sourceHandle).branchId
      ),
    };
  }
  if (sourceHandle?.startsWith(WEBHOOK_PREFIX)) {
    return {
      flow: applyWebhookConnection(flow, {
        sourceGroupId: source,
        sourceHandle,
        targetGroupId: target,
      }),
      edgeId: webhookEdgeId(
        source,
        parseWebhookHandleId(sourceHandle).actionId,
        parseWebhookHandleId(sourceHandle).branchId
      ),
    };
  }
  return null;
};

const onConnect = connection => {
  if (connection.source === connection.target) return;

  const groupIds = new Set((props.flowJson?.groups || []).map(g => g.id));
  if (!groupIds.has(connection.source) || !groupIds.has(connection.target)) {
    return;
  }

  let updatedFlow = props.flowJson;
  const branch = applyBranchConnection(updatedFlow, connection);

  if (branch) {
    updatedFlow = branch.flow;

    edges.value = edges.value.filter(
      e =>
        !(
          e.source === connection.source &&
          e.sourceHandle === connection.sourceHandle
        )
    );

    addEdge(
      {
        ...connection,
        id: branch.edgeId,
        targetHandle: 'target',
      },
      edges.value
    );

    lastGroupsSignature = groupsSignature(updatedFlow.groups);
  } else {
    updatedFlow = applyNextConnection(updatedFlow, {
      sourceGroupId: connection.source,
      targetGroupId: connection.target,
    });

    edges.value = edges.value.filter(
      e =>
        !(e.source === connection.source && isNextSourceHandle(e.sourceHandle))
    );

    addEdge(
      {
        ...connection,
        id: nextEdgeId(connection.source),
        sourceHandle: NEXT_HANDLE,
        targetHandle: 'target',
      },
      edges.value
    );

    lastGroupsSignature = groupsSignature(updatedFlow.groups);
  }

  persistFlow(updatedFlow, { rebuildEdges: true });
};

const onEdgesChange = changes => {
  if (skipFlowSync) return;

  let updatedFlow = props.flowJson;
  let flowChanged = false;

  changes.forEach(change => {
    if (change.type !== 'remove') return;

    const edge = change.item;
    const handle = edge?.sourceHandle;

    if (handle?.startsWith(CONDITION_PREFIX)) {
      updatedFlow = clearConditionConnection(updatedFlow, {
        sourceGroupId: edge.source,
        sourceHandle: handle,
      });
      flowChanged = true;
    } else if (handle?.startsWith(ASK_PREFIX)) {
      updatedFlow = clearAskConnection(updatedFlow, {
        sourceGroupId: edge.source,
        sourceHandle: handle,
      });
      flowChanged = true;
    } else if (handle?.startsWith(WEBHOOK_PREFIX)) {
      updatedFlow = clearWebhookConnection(updatedFlow, {
        sourceGroupId: edge.source,
        sourceHandle: handle,
      });
      flowChanged = true;
    } else if (isNextSourceHandle(handle)) {
      updatedFlow = clearNextConnection(updatedFlow, {
        sourceGroupId: edge.source,
      });
      flowChanged = true;
    }
  });

  if (flowChanged) {
    lastGroupsSignature = groupsSignature(updatedFlow.groups);
    persistFlow(updatedFlow, { rebuildEdges: true });
  }
};
</script>

<template>
  <VueFlow
    v-model:nodes="nodes"
    v-model:edges="edges"
    :node-types="nodeTypes"
    :is-valid-connection="isValidConnection"
    fit-view-on-init
    class="w-full h-full bg-n-surface-2"
    @connect="onConnect"
    @node-drag-stop="persistFlow()"
    @edges-change="onEdgesChange"
  >
    <Background />
    <Controls />
    <MiniMap />
  </VueFlow>
</template>
