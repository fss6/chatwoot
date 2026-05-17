<script setup>
import { computed, ref, watch, nextTick, onBeforeUnmount } from 'vue';
import { useI18n } from 'vue-i18n';
import { useToggle } from '@vueuse/core';
import { onClickOutside } from '@vueuse/core';
import Avatar from 'dashboard/components-next/avatar/Avatar.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import DropdownMenu from 'dashboard/components-next/dropdown-menu/DropdownMenu.vue';
import TeleportWithDirection from 'dashboard/components-next/TeleportWithDirection.vue';
import { useCrmTaskPresentation } from 'dashboard/composables/useCrmTaskPresentation';

const props = defineProps({
  task: { type: Object, required: true },
});

const emit = defineEmits(['complete', 'cancel', 'edit']);

const MENU_ESTIMATED_HEIGHT = 132;

const { t } = useI18n();
const { dueLabelFromDueAt, daysOverdue, taskTypeIcon } =
  useCrmTaskPresentation();
const [showMenu, toggleMenu] = useToggle();

const menuTriggerRef = ref(null);
const menuRef = ref(null);
const menuPosition = ref({ top: '0px', left: '0px', transform: '' });

const menuItems = computed(() => [
  {
    label: t('CRM_PIPELINE.TASKS.COMPLETE'),
    value: 'complete',
    action: 'complete',
    icon: 'i-lucide-check',
  },
  {
    label: t('CRM_PIPELINE.TASKS.CANCEL_TASK'),
    value: 'cancel',
    action: 'cancel',
    icon: 'i-lucide-ban',
  },
  {
    label: t('CRM_PIPELINE.TASKS.EDIT'),
    value: 'edit',
    action: 'edit',
    icon: 'i-lucide-pencil',
  },
]);

const overdueDays = computed(() => daysOverdue(props.task.due_at));

const dueLabel = computed(() => dueLabelFromDueAt(props.task.due_at));

const description = computed(() => props.task.description?.trim() || '');

const updateMenuPosition = () => {
  const el = menuTriggerRef.value;
  if (!el) return;

  const rect = el.getBoundingClientRect();
  const spaceBelow = window.innerHeight - rect.bottom;
  const openUp = spaceBelow < MENU_ESTIMATED_HEIGHT;

  menuPosition.value = {
    top: openUp ? `${rect.top - 4}px` : `${rect.bottom + 4}px`,
    left: `${rect.right}px`,
    transform: openUp ? 'translate(-100%, -100%)' : 'translateX(-100%)',
  };
};

const closeMenu = () => {
  if (showMenu.value) toggleMenu(false);
};

const handleScroll = () => closeMenu();

watch(showMenu, async isOpen => {
  if (isOpen) {
    await nextTick();
    updateMenuPosition();
    window.addEventListener('scroll', handleScroll, true);
    window.addEventListener('resize', updateMenuPosition);
  } else {
    window.removeEventListener('scroll', handleScroll, true);
    window.removeEventListener('resize', updateMenuPosition);
  }
});

onBeforeUnmount(() => {
  window.removeEventListener('scroll', handleScroll, true);
  window.removeEventListener('resize', updateMenuPosition);
});

onClickOutside([menuTriggerRef, menuRef], () => closeMenu());

const handleMenuAction = ({ action }) => {
  closeMenu();
  if (action === 'complete') {
    emit('complete', props.task);
  } else if (action === 'cancel') {
    emit('cancel', props.task);
  } else if (action === 'edit') {
    emit('edit', props.task);
  }
};
</script>

<template>
  <div class="rounded-2xl border border-n-weak bg-n-alpha-1 p-3">
    <p v-if="overdueDays" class="text-xs font-medium text-n-ruby-11 mb-2">
      {{
        $t('CRM_PIPELINE.DEAL.DAYS_OVERDUE', {
          count: overdueDays,
        })
      }}
    </p>

    <div class="flex items-start gap-3">
      <span
        class="mt-0.5 flex size-8 shrink-0 items-center justify-center rounded-full bg-n-solid-1 text-n-slate-10 shadow-sm"
      >
        <span
          class="size-4"
          :class="taskTypeIcon(task.task_type)"
          aria-hidden="true"
        />
      </span>

      <div class="min-w-0 flex-1">
        <p class="text-sm font-semibold text-n-slate-12">
          {{ task.title }}
        </p>
        <p
          v-if="description"
          class="text-xs text-n-slate-11 mt-0.5 line-clamp-2"
        >
          {{ description }}
        </p>
        <div class="flex flex-col gap-1 mt-1.5 text-xs text-n-slate-11">
          <span v-if="dueLabel">
            {{
              $t('CRM_PIPELINE.TASKS.DUE_AT_VALUE', {
                date: dueLabel,
              })
            }}
          </span>
          <span
            v-if="task.assigned_user"
            class="inline-flex items-center gap-1.5"
          >
            <Avatar :name="task.assigned_user.name" :size="18" rounded-full />
            <span>{{ task.assigned_user.name }}</span>
          </span>
        </div>
      </div>

      <div ref="menuTriggerRef" class="shrink-0">
        <Button
          icon="i-lucide-ellipsis-vertical"
          color="slate"
          size="xs"
          class="rounded-md"
          @click="toggleMenu()"
        />
      </div>
    </div>

    <TeleportWithDirection v-if="showMenu">
      <div ref="menuRef" class="fixed z-[9999]" :style="menuPosition">
        <DropdownMenu
          :menu-items="menuItems"
          class="!relative top-0 ltr:right-0 rtl:left-0"
          @action="handleMenuAction"
        />
      </div>
    </TeleportWithDirection>
  </div>
</template>
