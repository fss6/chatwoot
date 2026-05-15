export const CONDITION_PREFIX = 'condition:';
export const NEXT_HANDLE = 'next';
export const ASK_PREFIX = 'ask:';
export const WEBHOOK_PREFIX = 'webhook:';

export const CONDITION_SOURCES = [
  'session_variable',
  'contact',
  'conversation',
  'inbox',
  'datetime',
];

export const CONTACT_ATTRIBUTES = ['name', 'email', 'phone_number'];

export const CONVERSATION_ATTRIBUTES = ['labels'];

export const INBOX_ATTRIBUTES = ['working_now'];

export const DATETIME_ATTRIBUTES = ['hour', 'day_of_week', 'date'];

export const CONDITION_OPERATORS = [
  'equals',
  'not_equals',
  'contains',
  'not_contains',
  'starts_with',
  'ends_with',
  'exists',
  'not_exists',
  'greater_than',
  'less_than',
  'includes',
  'not_includes',
];

export const VALUE_OPTIONAL_OPERATORS = ['exists', 'not_exists'];

export const ARRAY_OPERATORS = ['includes', 'not_includes'];

export const attributesForSource = source => {
  switch (source) {
    case 'contact':
      return CONTACT_ATTRIBUTES;
    case 'conversation':
      return CONVERSATION_ATTRIBUTES;
    case 'inbox':
      return INBOX_ATTRIBUTES;
    case 'datetime':
      return DATETIME_ATTRIBUTES;
    default:
      return null;
  }
};

export const conditionHandleId = (actionId, branchId) =>
  `${CONDITION_PREFIX}${actionId}:${branchId}`;

export const parseConditionHandleId = handleId => {
  if (!handleId?.startsWith(CONDITION_PREFIX)) return null;
  const rest = handleId.slice(CONDITION_PREFIX.length);
  const colon = rest.indexOf(':');
  if (colon === -1) return null;
  return {
    actionId: rest.slice(0, colon),
    branchId: rest.slice(colon + 1),
  };
};

export const conditionEdgeId = (sourceGroupId, actionId, branchId) =>
  `cond_edge_${sourceGroupId}_${actionId}_${branchId}`;

export const nextEdgeId = sourceGroupId => `next_edge_${sourceGroupId}`;

export const isNextSourceHandle = handleId =>
  handleId === NEXT_HANDLE || handleId === 'source';

export const removeGroupFromFlow = (flowJson, groupId) => {
  const groups = (flowJson.groups || [])
    .filter(g => g.id !== groupId)
    .map(g => ({
      ...g,
      next_group_id: g.next_group_id === groupId ? '' : g.next_group_id,
      actions: (g.actions || []).map(action => {
        if (
          action.type === 'go_to_group' &&
          action.data?.target_group_id === groupId
        ) {
          return {
            ...action,
            data: { ...action.data, target_group_id: '' },
          };
        }
        if (action.type === 'condition') {
          const data = { ...(action.data || {}) };
          data.rules = (data.rules || []).map(rule =>
            rule.target_group_id === groupId
              ? { ...rule, target_group_id: '' }
              : rule
          );
          if (data.fallback_group_id === groupId) data.fallback_group_id = '';
          return { ...action, data };
        }

        if (action.type === 'ask') {
          const data = { ...(action.data || {}) };
          data.options = (data.options || []).map(opt =>
            opt.target_group_id === groupId
              ? { ...opt, target_group_id: '' }
              : opt
          );
          if (data.timeout_group_id === groupId) data.timeout_group_id = '';
          if (data.invalid_response_group_id === groupId)
            data.invalid_response_group_id = '';
          return { ...action, data };
        }

        if (action.type === 'send_webhook') {
          const data = { ...(action.data || {}) };
          if (data.success_group_id === groupId) data.success_group_id = '';
          if (data.failure_group_id === groupId) data.failure_group_id = '';
          return { ...action, data };
        }

        return action;
      }),
    }));

  const edges = (flowJson.edges || []).filter(
    e =>
      e.source !== groupId &&
      e.target !== groupId &&
      !(e.source === groupId && isNextSourceHandle(e.sourceHandle))
  );

  let entryGroupId = flowJson.entry_group_id;
  if (entryGroupId === groupId) {
    entryGroupId = groups[0]?.id || '';
  }

  return { ...flowJson, groups, edges, entry_group_id: entryGroupId };
};

export const removeEdgesForAction = (edgeList, groupId, actionId) =>
  (edgeList || []).filter(edge => {
    if (edge.source !== groupId) return true;
    const handle = edge.sourceHandle;
    const matchedPrefix = [CONDITION_PREFIX, ASK_PREFIX, WEBHOOK_PREFIX].find(
      p => handle?.startsWith(p)
    );
    if (matchedPrefix)
      return !handle.startsWith(`${matchedPrefix}${actionId}:`);
    return true;
  });

export const sanitizeEdges = (edgeList, groups) => {
  const groupIds = new Set((groups || []).map(g => g.id));
  const seen = new Set();
  return (edgeList || []).filter(edge => {
    if (!groupIds.has(edge.source) || !groupIds.has(edge.target)) return false;
    if (seen.has(edge.id)) return false;
    seen.add(edge.id);
    return true;
  });
};

export const createCondition = () => ({
  source: 'session_variable',
  attribute: '',
  operator: 'equals',
  value: '',
});

export const createRule = (index = 1) => ({
  id: `rule_${crypto.randomUUID().slice(0, 8)}`,
  label: `Branch ${index}`,
  logic: 'and',
  conditions: [createCondition()],
  target_group_id: '',
});

export const defaultConditionData = () => ({
  rules: [createRule(1)],
  fallback_group_id: '',
  fallback_label: 'Default case',
});

const operatorNeedsValue = operator =>
  !VALUE_OPTIONAL_OPERATORS.includes(operator);

export const buildNextEdgesFromGroups = groups => {
  const edges = [];
  (groups || []).forEach(group => {
    if (!group.next_group_id) return;
    edges.push({
      id: nextEdgeId(group.id),
      source: group.id,
      sourceHandle: NEXT_HANDLE,
      target: group.next_group_id,
      targetHandle: 'target',
    });
  });
  return edges;
};

export const migrateFlowNextGroups = flowJson => {
  const groupMap = new Map((flowJson.groups || []).map(g => [g.id, { ...g }]));
  const edges = [];

  (flowJson.edges || []).forEach(edge => {
    if (edge.sourceHandle?.startsWith(CONDITION_PREFIX)) {
      edges.push(edge);
      return;
    }

    if (isNextSourceHandle(edge.sourceHandle)) {
      const group = groupMap.get(edge.source);
      if (group && !group.next_group_id && edge.target) {
        groupMap.set(edge.source, { ...group, next_group_id: edge.target });
      }
      return;
    }

    edges.push(edge);
  });

  return {
    ...flowJson,
    groups: (flowJson.groups || []).map(g => groupMap.get(g.id) || g),
    edges,
  };
};

export const applyNextConnection = (
  flowJson,
  { sourceGroupId, targetGroupId }
) => {
  const groups = flowJson.groups.map(group =>
    group.id === sourceGroupId
      ? { ...group, next_group_id: targetGroupId }
      : group
  );
  return { ...flowJson, groups };
};

export const clearNextConnection = (flowJson, { sourceGroupId }) => {
  const groups = flowJson.groups.map(group =>
    group.id === sourceGroupId ? { ...group, next_group_id: '' } : group
  );
  return { ...flowJson, groups };
};

export const buildConditionEdgesFromGroups = groups => {
  const edges = [];
  (groups || []).forEach(group => {
    (group.actions || []).forEach(action => {
      if (action.type !== 'condition') return;
      const data = action.data || {};
      (data.rules || []).forEach(rule => {
        if (!rule.target_group_id) return;
        edges.push({
          id: conditionEdgeId(group.id, action.id, rule.id),
          source: group.id,
          sourceHandle: conditionHandleId(action.id, rule.id),
          target: rule.target_group_id,
          targetHandle: 'target',
        });
      });
      if (data.fallback_group_id) {
        edges.push({
          id: conditionEdgeId(group.id, action.id, 'fallback'),
          source: group.id,
          sourceHandle: conditionHandleId(action.id, 'fallback'),
          target: data.fallback_group_id,
          targetHandle: 'target',
        });
      }
    });
  });
  return edges;
};

export const partitionFlowEdges = flowEdges =>
  (flowEdges || []).filter(edge =>
    edge.sourceHandle?.startsWith(CONDITION_PREFIX)
  );

export const applyConditionConnection = (
  flowJson,
  { sourceGroupId, sourceHandle, targetGroupId }
) => {
  const parsed = parseConditionHandleId(sourceHandle);
  if (!parsed) return flowJson;

  const groups = flowJson.groups.map(group => {
    if (group.id !== sourceGroupId) return group;
    return {
      ...group,
      actions: group.actions.map(action => {
        if (action.id !== parsed.actionId || action.type !== 'condition') {
          return action;
        }
        const data = { ...(action.data || {}) };
        if (parsed.branchId === 'fallback') {
          data.fallback_group_id = targetGroupId;
        } else {
          data.rules = (data.rules || []).map(rule =>
            rule.id === parsed.branchId
              ? { ...rule, target_group_id: targetGroupId }
              : rule
          );
        }
        return { ...action, data };
      }),
    };
  });

  return { ...flowJson, groups };
};

export const clearConditionConnection = (
  flowJson,
  { sourceGroupId, sourceHandle }
) => {
  const parsed = parseConditionHandleId(sourceHandle);
  if (!parsed) return flowJson;

  const groups = flowJson.groups.map(group => {
    if (group.id !== sourceGroupId) return group;
    return {
      ...group,
      actions: group.actions.map(action => {
        if (action.id !== parsed.actionId || action.type !== 'condition') {
          return action;
        }
        const data = { ...(action.data || {}) };
        if (parsed.branchId === 'fallback') {
          data.fallback_group_id = '';
        } else {
          data.rules = (data.rules || []).map(rule =>
            rule.id === parsed.branchId
              ? { ...rule, target_group_id: '' }
              : rule
          );
        }
        return { ...action, data };
      }),
    };
  });

  return { ...flowJson, groups };
};

// ─── ASK helpers ────────────────────────────────────────────────────────────

export const askHandleId = (actionId, branchId) =>
  `${ASK_PREFIX}${actionId}:${branchId}`;

export const parseAskHandleId = handleId => {
  if (!handleId?.startsWith(ASK_PREFIX)) return null;
  const rest = handleId.slice(ASK_PREFIX.length);
  const colon = rest.indexOf(':');
  if (colon === -1) return null;
  return { actionId: rest.slice(0, colon), branchId: rest.slice(colon + 1) };
};

export const askEdgeId = (sourceGroupId, actionId, branchId) =>
  `ask_edge_${sourceGroupId}_${actionId}_${branchId}`;

export const buildAskEdgesFromGroups = groups => {
  const edges = [];
  (groups || []).forEach(group => {
    (group.actions || []).forEach(action => {
      if (action.type !== 'ask') return;
      const data = action.data || {};
      (data.options || []).forEach(opt => {
        if (!opt.target_group_id) return;
        edges.push({
          id: askEdgeId(group.id, action.id, opt.id),
          source: group.id,
          sourceHandle: askHandleId(action.id, opt.id),
          target: opt.target_group_id,
          targetHandle: 'target',
        });
      });
      if (data.timeout_group_id) {
        edges.push({
          id: askEdgeId(group.id, action.id, 'timeout'),
          source: group.id,
          sourceHandle: askHandleId(action.id, 'timeout'),
          target: data.timeout_group_id,
          targetHandle: 'target',
        });
      }
      if (data.invalid_response_group_id) {
        edges.push({
          id: askEdgeId(group.id, action.id, 'invalid'),
          source: group.id,
          sourceHandle: askHandleId(action.id, 'invalid'),
          target: data.invalid_response_group_id,
          targetHandle: 'target',
        });
      }
    });
  });
  return edges;
};

export const applyAskConnection = (
  flowJson,
  { sourceGroupId, sourceHandle, targetGroupId }
) => {
  const parsed = parseAskHandleId(sourceHandle);
  if (!parsed) return flowJson;

  const groups = flowJson.groups.map(group => {
    if (group.id !== sourceGroupId) return group;
    return {
      ...group,
      actions: group.actions.map(action => {
        if (action.id !== parsed.actionId || action.type !== 'ask')
          return action;
        const data = { ...(action.data || {}) };
        if (parsed.branchId === 'timeout') {
          data.timeout_group_id = targetGroupId;
        } else if (parsed.branchId === 'invalid') {
          data.invalid_response_group_id = targetGroupId;
        } else {
          data.options = (data.options || []).map(opt =>
            opt.id === parsed.branchId
              ? { ...opt, target_group_id: targetGroupId }
              : opt
          );
        }
        return { ...action, data };
      }),
    };
  });
  return { ...flowJson, groups };
};

export const clearAskConnection = (
  flowJson,
  { sourceGroupId, sourceHandle }
) => {
  const parsed = parseAskHandleId(sourceHandle);
  if (!parsed) return flowJson;

  const groups = flowJson.groups.map(group => {
    if (group.id !== sourceGroupId) return group;
    return {
      ...group,
      actions: group.actions.map(action => {
        if (action.id !== parsed.actionId || action.type !== 'ask')
          return action;
        const data = { ...(action.data || {}) };
        if (parsed.branchId === 'timeout') {
          data.timeout_group_id = '';
        } else if (parsed.branchId === 'invalid') {
          data.invalid_response_group_id = '';
        } else {
          data.options = (data.options || []).map(opt =>
            opt.id === parsed.branchId ? { ...opt, target_group_id: '' } : opt
          );
        }
        return { ...action, data };
      }),
    };
  });
  return { ...flowJson, groups };
};

// ─── WEBHOOK helpers ─────────────────────────────────────────────────────────

export const webhookHandleId = (actionId, branchId) =>
  `${WEBHOOK_PREFIX}${actionId}:${branchId}`;

export const parseWebhookHandleId = handleId => {
  if (!handleId?.startsWith(WEBHOOK_PREFIX)) return null;
  const rest = handleId.slice(WEBHOOK_PREFIX.length);
  const colon = rest.indexOf(':');
  if (colon === -1) return null;
  return { actionId: rest.slice(0, colon), branchId: rest.slice(colon + 1) };
};

export const webhookEdgeId = (sourceGroupId, actionId, branchId) =>
  `wh_edge_${sourceGroupId}_${actionId}_${branchId}`;

export const buildWebhookEdgesFromGroups = groups => {
  const edges = [];
  (groups || []).forEach(group => {
    (group.actions || []).forEach(action => {
      if (action.type !== 'send_webhook' || !action.data?.wait_response) return;
      const data = action.data || {};
      if (data.success_group_id) {
        edges.push({
          id: webhookEdgeId(group.id, action.id, 'success'),
          source: group.id,
          sourceHandle: webhookHandleId(action.id, 'success'),
          target: data.success_group_id,
          targetHandle: 'target',
        });
      }
      if (data.failure_group_id) {
        edges.push({
          id: webhookEdgeId(group.id, action.id, 'failure'),
          source: group.id,
          sourceHandle: webhookHandleId(action.id, 'failure'),
          target: data.failure_group_id,
          targetHandle: 'target',
        });
      }
    });
  });
  return edges;
};

export const applyWebhookConnection = (
  flowJson,
  { sourceGroupId, sourceHandle, targetGroupId }
) => {
  const parsed = parseWebhookHandleId(sourceHandle);
  if (!parsed) return flowJson;

  const groups = flowJson.groups.map(group => {
    if (group.id !== sourceGroupId) return group;
    return {
      ...group,
      actions: group.actions.map(action => {
        if (action.id !== parsed.actionId || action.type !== 'send_webhook')
          return action;
        const data = { ...(action.data || {}) };
        if (parsed.branchId === 'success') {
          data.success_group_id = targetGroupId;
        } else if (parsed.branchId === 'failure') {
          data.failure_group_id = targetGroupId;
        }
        return { ...action, data };
      }),
    };
  });
  return { ...flowJson, groups };
};

export const clearWebhookConnection = (
  flowJson,
  { sourceGroupId, sourceHandle }
) => {
  const parsed = parseWebhookHandleId(sourceHandle);
  if (!parsed) return flowJson;

  const groups = flowJson.groups.map(group => {
    if (group.id !== sourceGroupId) return group;
    return {
      ...group,
      actions: group.actions.map(action => {
        if (action.id !== parsed.actionId || action.type !== 'send_webhook')
          return action;
        const data = { ...(action.data || {}) };
        if (parsed.branchId === 'success') data.success_group_id = '';
        else if (parsed.branchId === 'failure') data.failure_group_id = '';
        return { ...action, data };
      }),
    };
  });
  return { ...flowJson, groups };
};

export const mergeFlowEdges = groups =>
  sanitizeEdges(
    [
      ...buildNextEdgesFromGroups(groups),
      ...buildConditionEdgesFromGroups(groups),
      ...buildAskEdgesFromGroups(groups),
      ...buildWebhookEdgesFromGroups(groups),
    ],
    groups
  );

export const summarizeRule = (rule, t) => {
  let conditions;
  if (rule.conditions?.length) {
    conditions = rule.conditions;
  } else if (rule.field) {
    conditions = [
      {
        source: 'session_variable',
        attribute: rule.field,
        operator: rule.operator,
        value: rule.value,
      },
    ];
  } else {
    conditions = [];
  }

  if (!conditions.length) return rule.label || '';

  const parts = conditions.map(c => {
    const sourceLabel = t(
      `WL_BOT_FLOWS.CONDITION.SOURCES.${c.source.toUpperCase()}`
    );
    const attr = c.attribute || '';
    const op = t(
      `WL_BOT_FLOWS.CONDITION.OPERATORS.${c.operator.toUpperCase()}`
    );
    const val = operatorNeedsValue(c.operator) ? ` "${c.value}"` : '';
    return `${sourceLabel} ${attr} ${op}${val}`;
  });

  const joiner =
    rule.logic === 'or'
      ? ` ${t('WL_BOT_FLOWS.CONDITION.LOGIC_OR')} `
      : ` ${t('WL_BOT_FLOWS.CONDITION.LOGIC_AND')} `;

  return `${rule.label}: ${parts.join(joiner)}`;
};
