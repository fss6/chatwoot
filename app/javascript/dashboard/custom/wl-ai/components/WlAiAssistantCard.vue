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
  name: {
    type: String,
    required: true,
  },
  description: {
    type: String,
    default: '',
  },
  updatedAt: {
    type: String,
    default: '',
  },
});

const emit = defineEmits(['action', 'openFaqs']);
const { checkPermissions } = usePolicy();
const { t } = useI18n();

const [showActionsDropdown, toggleDropdown] = useToggle();

const menuItems = computed(() => {
  const items = [
    {
      label: t('WL_AI.ASSISTANTS.OPTIONS.OPEN_FAQS'),
      value: 'faqs',
      action: 'faqs',
      icon: 'i-lucide-message-circle-question',
    },
  ];
  if (checkPermissions(['administrator'])) {
    items.push(
      {
        label: t('WL_AI.ASSISTANTS.OPTIONS.EDIT'),
        value: 'edit',
        action: 'edit',
        icon: 'i-lucide-pencil-line',
      },
      {
        label: t('WL_AI.ASSISTANTS.OPTIONS.DELETE'),
        value: 'delete',
        action: 'delete',
        icon: 'i-lucide-trash',
      }
    );
  }
  return items;
});

const lastUpdatedAt = computed(() => {
  if (!props.updatedAt) return '';
  const ms = Date.parse(props.updatedAt);
  if (Number.isNaN(ms)) return '';
  return dynamicTime(ms / 1000);
});

const handleAction = ({ action }) => {
  toggleDropdown(false);
  if (action === 'faqs') {
    emit('openFaqs', props.id);
    return;
  }
  emit('action', { action, id: props.id });
};
</script>

<template>
  <CardLayout>
    <div class="flex justify-between w-full gap-1">
      <button
        type="button"
        class="text-start min-w-0 flex-1 p-0 border-0 bg-transparent cursor-pointer"
        @click="emit('openFaqs', id)"
      >
        <h6
          class="text-base font-normal text-n-slate-12 line-clamp-1 hover:underline transition-colors"
        >
          {{ name }}
        </h6>
      </button>
      <div class="flex items-center gap-2 shrink-0">
        <div
          v-on-clickaway="() => toggleDropdown(false)"
          class="relative flex items-center group"
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
            class="mt-1 ltr:right-0 rtl:left-0 top-full"
            @action="handleAction($event)"
          />
        </div>
      </div>
    </div>
    <div class="flex items-center justify-between w-full gap-4">
      <span class="text-sm truncate text-n-slate-11">
        {{ description }}
      </span>
      <span class="text-sm text-n-slate-11 line-clamp-1 shrink-0">
        {{ lastUpdatedAt }}
      </span>
    </div>
  </CardLayout>
</template>
