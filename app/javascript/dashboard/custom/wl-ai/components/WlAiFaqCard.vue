<script setup>
import { computed } from 'vue';
import { useToggle } from '@vueuse/core';
import { useI18n } from 'vue-i18n';
import { dynamicTime } from 'shared/helpers/timeHelper';
import { usePolicy } from 'dashboard/composables/usePolicy';

import CardLayout from 'dashboard/components-next/CardLayout.vue';
import DropdownMenu from 'dashboard/components-next/dropdown-menu/DropdownMenu.vue';
import Button from 'dashboard/components-next/button/Button.vue';

const props = defineProps({
  id: {
    type: Number,
    required: true,
  },
  question: {
    type: String,
    required: true,
  },
  answer: {
    type: String,
    required: true,
  },
  updatedAt: {
    type: String,
    default: '',
  },
});

const emit = defineEmits(['action']);
const { checkPermissions } = usePolicy();
const { t } = useI18n();

const [showActionsDropdown, toggleDropdown] = useToggle();

const menuItems = computed(() => {
  if (!checkPermissions(['administrator'])) {
    return [];
  }
  return [
    {
      label: t('WL_AI.FAQS.EDIT'),
      value: 'edit',
      action: 'edit',
      icon: 'i-lucide-pencil-line',
    },
    {
      label: t('WL_AI.FAQS.DELETE'),
      value: 'delete',
      action: 'delete',
      icon: 'i-lucide-trash',
    },
  ];
});

const timestamp = computed(() => {
  if (!props.updatedAt) return '';
  const ms = Date.parse(props.updatedAt);
  if (Number.isNaN(ms)) return '';
  return dynamicTime(ms / 1000);
});

const handleAction = ({ action }) => {
  toggleDropdown(false);
  emit('action', { action, id: props.id });
};

const plainAnswerPreview = computed(() => {
  const raw = props.answer || '';
  return raw
    .replace(/<[^>]+>/g, ' ')
    .replace(/\s+/g, ' ')
    .trim();
});
</script>

<template>
  <CardLayout class="relative">
    <div class="flex relative justify-between w-full gap-1">
      <span class="text-base text-n-slate-12 line-clamp-1 min-w-0">
        {{ question }}
      </span>
      <div
        v-if="menuItems.length"
        v-on-clickaway="() => toggleDropdown(false)"
        class="relative flex items-center group shrink-0"
      >
        <Button
          icon="i-lucide-ellipsis-vertical"
          color="slate"
          size="xs"
          class="rounded-md group-hover:bg-n-alpha-2"
          @click="toggleDropdown()"
        />
        <DropdownMenu
          v-if="showActionsDropdown"
          :menu-items="menuItems"
          class="mt-1 ltr:right-0 rtl:right-0 top-full"
          @action="handleAction($event)"
        />
      </div>
    </div>
    <span class="text-n-slate-11 text-sm line-clamp-5">
      {{ plainAnswerPreview }}
    </span>
    <div
      class="flex items-center justify-end w-full gap-2 mt-2 text-sm text-n-slate-11"
    >
      <span>{{ timestamp }}</span>
    </div>
  </CardLayout>
</template>
