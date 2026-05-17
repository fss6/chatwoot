<script setup>
import { ref, computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { debounce } from '@chatwoot/utils';
import ComboBox from 'dashboard/components-next/combobox/ComboBox.vue';
import { createContactSearcher } from 'dashboard/components-next/NewConversation/helpers/composeConversationHelper';
import CrmPipelineFormField from './CrmPipelineFormField.vue';

const props = defineProps({
  modelValue: { type: [Number, String], default: null },
  lockedContact: { type: Object, default: null },
  disabled: { type: Boolean, default: false },
  bare: { type: Boolean, default: false },
});

const emit = defineEmits(['update:modelValue']);

const { t } = useI18n();
const searchContacts = createContactSearcher();
const searchResults = ref([]);
const isSearching = ref(false);

const contactOptions = computed(() =>
  searchResults.value.map(contact => ({
    value: contact.id,
    label: [contact.name, contact.email || contact.phoneNumber]
      .filter(Boolean)
      .join(' · '),
  }))
);

const emptyState = computed(() => {
  if (isSearching.value) return t('CRM_PIPELINE.CONTACT.SEARCHING');
  return t('CRM_PIPELINE.CONTACT.EMPTY');
});

const debouncedSearch = debounce(async query => {
  isSearching.value = true;
  try {
    const results = await searchContacts(query);
    searchResults.value = results ?? [];
  } finally {
    isSearching.value = false;
  }
}, 300);

const handleSearch = query => {
  debouncedSearch(query);
};

const handleSelect = contactId => {
  emit('update:modelValue', contactId ? Number(contactId) : null);
};

const lockedLabel = computed(() => {
  if (!props.lockedContact) return '';
  const contact = props.lockedContact;
  const emailOrPhone =
    contact.email || contact.phone_number || contact.phoneNumber;
  return [contact.name, emailOrPhone].filter(Boolean).join(' · ');
});
</script>

<template>
  <CrmPipelineFormField v-if="!bare" :label="$t('CRM_PIPELINE.DEAL.CONTACT')">
    <p v-if="lockedContact" class="text-sm text-n-slate-11 mb-0">
      {{ lockedLabel }}
    </p>
    <ComboBox
      v-else
      use-api-results
      :model-value="modelValue"
      :options="contactOptions"
      :disabled="disabled"
      :empty-state="emptyState"
      :search-placeholder="$t('CRM_PIPELINE.CONTACT.SEARCH_PLACEHOLDER')"
      :placeholder="$t('CRM_PIPELINE.CONTACT.PLACEHOLDER')"
      class="w-full"
      @search="handleSearch"
      @update:model-value="handleSelect"
    />
  </CrmPipelineFormField>
  <template v-else>
    <p v-if="lockedContact" class="mb-0 truncate">
      {{ lockedLabel }}
    </p>
    <ComboBox
      v-else
      use-api-results
      :model-value="modelValue"
      :options="contactOptions"
      :disabled="disabled"
      :empty-state="emptyState"
      :search-placeholder="$t('CRM_PIPELINE.CONTACT.SEARCH_PLACEHOLDER')"
      :placeholder="$t('CRM_PIPELINE.CONTACT.PLACEHOLDER')"
      class="w-full"
      @search="handleSearch"
      @update:model-value="handleSelect"
    />
  </template>
</template>
