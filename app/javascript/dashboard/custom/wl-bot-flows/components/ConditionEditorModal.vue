<script setup>
import { ref, watch, computed } from 'vue';
import { useI18n } from 'vue-i18n';
import Dialog from 'dashboard/components-next/dialog/Dialog.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import {
  CONDITION_OPERATORS,
  CONDITION_SOURCES,
  VALUE_OPTIONAL_OPERATORS,
  ARRAY_OPERATORS,
  attributesForSource,
  createCondition,
  createRule,
} from '../constants/conditionConfig';

const props = defineProps({
  action: {
    type: Object,
    required: true,
  },
  groups: {
    type: Array,
    default: () => [],
  },
});

const emit = defineEmits(['save', 'close']);

const { t } = useI18n();
const dialogRef = ref(null);
const draft = ref(null);

const resetDraft = () => {
  draft.value = JSON.parse(JSON.stringify(props.action.data || {}));
  if (!draft.value.rules?.length) {
    draft.value.rules = [createRule(1)];
  }
  if (!draft.value.fallback_label) {
    draft.value.fallback_label = t('WL_BOT_FLOWS.CONDITION.FALLBACK_LABEL');
  }
};

watch(
  () => props.action,
  () => resetDraft(),
  { immediate: true, deep: true }
);

const isCustomAttributeSource = source =>
  source === 'contact' || source === 'conversation';

const sourceHasFixedAttributes = source => {
  const attrs = attributesForSource(source);
  return attrs !== null;
};

const getAttributeOptions = source => attributesForSource(source) || [];

const isCustomAttributeField = (source, attribute) =>
  isCustomAttributeSource(source) && attribute?.startsWith('custom_attribute:');

const customAttributeKey = attribute =>
  attribute?.startsWith('custom_attribute:')
    ? attribute.slice('custom_attribute:'.length)
    : '';

const setCustomAttributeKey = (condition, key) => {
  condition.attribute = `custom_attribute:${key}`;
};

const needsValue = operator =>
  !VALUE_OPTIONAL_OPERATORS.includes(operator) &&
  !ARRAY_OPERATORS.includes(operator);

const operatorOptions = computed(() => CONDITION_OPERATORS);

const addRule = () => {
  draft.value.rules.push(createRule(draft.value.rules.length + 1));
};

const removeRule = ruleId => {
  draft.value.rules = draft.value.rules.filter(r => r.id !== ruleId);
};

const addCondition = rule => {
  rule.conditions.push(createCondition());
};

const removeCondition = (rule, index) => {
  rule.conditions.splice(index, 1);
};

const onSourceChange = (condition, source) => {
  condition.source = source;
  const attrs = attributesForSource(source);
  condition.attribute = attrs ? attrs[0] : '';
  condition.operator = 'equals';
};

const handleConfirm = () => {
  emit('save', { ...draft.value });
  dialogRef.value?.close();
};

const handleClose = () => {
  emit('close');
};

defineExpose({
  open: () => {
    resetDraft();
    dialogRef.value?.open();
  },
});
</script>

<template>
  <Dialog
    ref="dialogRef"
    type="edit"
    width="3xl"
    overflow-y-auto
    :title="$t('WL_BOT_FLOWS.CONDITION.MODAL_TITLE')"
    :description="$t('WL_BOT_FLOWS.CONDITION.MODAL_DESCRIPTION')"
    :confirm-button-label="$t('WL_BOT_FLOWS.CONDITION.SAVE')"
    :cancel-button-label="$t('DIALOG.BUTTONS.CANCEL')"
    @confirm="handleConfirm"
    @close="handleClose"
  >
    <p class="text-xs text-n-slate-11 mb-4">
      {{ $t('WL_BOT_FLOWS.CONDITION.HELP_TEXT') }}
    </p>

    <div
      v-for="rule in draft?.rules || []"
      :key="rule.id"
      class="mb-4 p-3 border rounded-lg border-n-weak bg-n-solid-2"
    >
      <div class="flex items-center gap-2 mb-3">
        <input
          v-model="rule.label"
          class="flex-1 px-2 py-1 text-sm border rounded border-n-weak bg-n-solid-1 text-n-slate-12"
          :placeholder="$t('WL_BOT_FLOWS.CONDITION.RULE_LABEL')"
        />
        <select
          v-model="rule.logic"
          class="px-2 py-1 text-xs border rounded border-n-weak bg-n-solid-1 text-n-slate-12"
        >
          <option value="and">
            {{ $t('WL_BOT_FLOWS.CONDITION.LOGIC_AND') }}
          </option>
          <option value="or">
            {{ $t('WL_BOT_FLOWS.CONDITION.LOGIC_OR') }}
          </option>
        </select>
        <Button
          ghost
          xs
          :label="$t('WL_BOT_FLOWS.CONDITION.REMOVE_RULE')"
          @click="removeRule(rule.id)"
        />
      </div>

      <div
        v-for="(condition, condIndex) in rule.conditions"
        :key="condIndex"
        class="flex flex-wrap items-center gap-2 mb-2"
      >
        <span class="text-xs text-n-slate-11 w-8 shrink-0">
          {{
            condIndex === 0
              ? $t('WL_BOT_FLOWS.CONDITION.IF')
              : $t('WL_BOT_FLOWS.CONDITION.AND')
          }}
        </span>

        <!-- Source -->
        <select
          v-model="condition.source"
          class="px-2 py-1 text-xs border rounded border-n-weak bg-n-solid-1 text-n-slate-12"
          @change="onSourceChange(condition, condition.source)"
        >
          <option
            v-for="source in CONDITION_SOURCES"
            :key="source"
            :value="source"
          >
            {{ $t(`WL_BOT_FLOWS.CONDITION.SOURCES.${source.toUpperCase()}`) }}
          </option>
        </select>

        <!-- Attribute: fixed list -->
        <select
          v-if="
            sourceHasFixedAttributes(condition.source) &&
            !isCustomAttributeField(condition.source, condition.attribute)
          "
          v-model="condition.attribute"
          class="px-2 py-1 text-xs border rounded border-n-weak bg-n-solid-1 text-n-slate-12"
        >
          <option
            v-for="attr in getAttributeOptions(condition.source)"
            :key="attr"
            :value="attr"
          >
            {{ attr }}
          </option>
          <option
            v-if="isCustomAttributeSource(condition.source)"
            value="custom_attribute:"
          >
            {{ $t('WL_BOT_FLOWS.CONDITION.CUSTOM_ATTRIBUTE') }}
          </option>
        </select>

        <!-- Attribute: free text for session_variable or custom attribute key -->
        <template
          v-else-if="
            isCustomAttributeField(condition.source, condition.attribute)
          "
        >
          <input
            :value="customAttributeKey(condition.attribute)"
            class="px-2 py-1 text-xs border rounded border-n-weak bg-n-solid-1 text-n-slate-12 min-w-[6rem]"
            :placeholder="$t('WL_BOT_FLOWS.CONDITION.CUSTOM_ATTRIBUTE_KEY')"
            @input="setCustomAttributeKey(condition, $event.target.value)"
          />
        </template>

        <input
          v-else
          v-model="condition.attribute"
          class="px-2 py-1 text-xs border rounded border-n-weak bg-n-solid-1 text-n-slate-12 min-w-[6rem]"
          :placeholder="$t('WL_BOT_FLOWS.CONDITION.VARIABLE_NAME')"
        />

        <!-- Operator -->
        <select
          v-model="condition.operator"
          class="px-2 py-1 text-xs border rounded border-n-weak bg-n-solid-1 text-n-slate-12"
        >
          <option v-for="op in operatorOptions" :key="op" :value="op">
            {{ $t(`WL_BOT_FLOWS.CONDITION.OPERATORS.${op.toUpperCase()}`) }}
          </option>
        </select>

        <!-- Value -->
        <input
          v-if="needsValue(condition.operator)"
          v-model="condition.value"
          class="flex-1 min-w-[5rem] px-2 py-1 text-xs border rounded border-n-weak bg-n-solid-1 text-n-slate-12"
          :placeholder="$t('WL_BOT_FLOWS.CONDITION.VALUE')"
        />

        <Button
          v-if="rule.conditions.length > 1"
          ghost
          xs
          :label="$t('WL_BOT_FLOWS.CONDITION.REMOVE_CONDITION')"
          @click="removeCondition(rule, condIndex)"
        />
      </div>

      <Button
        ghost
        xs
        class="mb-3"
        :label="$t('WL_BOT_FLOWS.CONDITION.ADD_CONDITION')"
        @click="addCondition(rule)"
      />

      <label class="text-xs text-n-slate-11">{{
        $t('WL_BOT_FLOWS.CONDITION.TARGET_GROUP')
      }}</label>
      <select
        v-model="rule.target_group_id"
        class="w-full mt-1 px-2 py-1 text-sm border rounded border-n-weak bg-n-solid-1 text-n-slate-12"
      >
        <option value="">
          {{ $t('WL_BOT_FLOWS.CONDITION.SELECT_GROUP') }}
        </option>
        <option v-for="g in groups" :key="g.id" :value="g.id">
          {{ g.name }} ({{ g.id }})
        </option>
      </select>
    </div>

    <Button
      ghost
      sm
      class="mb-4"
      :label="$t('WL_BOT_FLOWS.CONDITION.ADD_RULE')"
      @click="addRule"
    />

    <div class="p-3 border rounded-lg border-n-weak bg-n-solid-2">
      <label class="text-xs font-medium text-n-slate-12">
        {{ $t('WL_BOT_FLOWS.CONDITION.FALLBACK_SECTION') }}
      </label>
      <input
        v-model="draft.fallback_label"
        class="w-full mt-2 px-2 py-1 text-sm border rounded border-n-weak bg-n-solid-1 text-n-slate-12"
        :placeholder="$t('WL_BOT_FLOWS.CONDITION.FALLBACK_LABEL')"
      />
      <select
        v-model="draft.fallback_group_id"
        class="w-full mt-2 px-2 py-1 text-sm border rounded border-n-weak bg-n-solid-1 text-n-slate-12"
      >
        <option value="">
          {{ $t('WL_BOT_FLOWS.CONDITION.SELECT_GROUP') }}
        </option>
        <option v-for="g in groups" :key="g.id" :value="g.id">
          {{ g.name }} ({{ g.id }})
        </option>
      </select>
    </div>
  </Dialog>
</template>
