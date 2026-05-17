<script setup>
import { computed } from 'vue';
import Avatar from 'dashboard/components-next/avatar/Avatar.vue';

const props = defineProps({
  tasks: { type: Array, default: () => [] },
  isLoading: { type: Boolean, default: false },
});

const emit = defineEmits(['complete', 'add']);

const taskTypeIcon = {
  call: 'i-lucide-phone',
  meeting: 'i-lucide-calendar',
  follow_up: 'i-lucide-message-circle',
  send_proposal: 'i-lucide-file-text',
  send_contract: 'i-lucide-file-signature',
  payment_check: 'i-lucide-wallet',
  other: 'i-lucide-list-checks',
};

const daysOverdue = dueAt => {
  if (!dueAt) return null;
  const diff = Math.floor((Date.now() - new Date(dueAt).getTime()) / 86400000);
  return diff > 0 ? diff : null;
};

const formatDue = dueAt => {
  if (!dueAt) return null;
  return new Date(dueAt).toLocaleString();
};

const pendingTasks = computed(() =>
  props.tasks.filter(task => task.status === 'pending')
);
</script>

<template>
  <section class="space-y-3">
    <div class="flex items-center justify-between gap-2">
      <h3 class="text-sm font-semibold text-n-slate-12">
        {{ $t('CRM_PIPELINE.DEAL.PLANNED_ACTIVITIES') }}
      </h3>
      <button
        type="button"
        class="text-xs font-medium text-n-blue-11 hover:underline"
        @click="emit('add')"
      >
        {{ $t('CRM_PIPELINE.TASKS.ADD_TASK') }}
      </button>
    </div>

    <p v-if="isLoading" class="text-xs text-n-slate-11">
      {{ $t('CRM_PIPELINE.LOADING') }}
    </p>

    <ul v-else-if="pendingTasks.length" class="space-y-4">
      <li
        v-for="task in pendingTasks"
        :key="task.id"
        class="border-b border-n-weak pb-4 last:border-0 last:pb-0"
      >
        <p
          v-if="daysOverdue(task.due_at)"
          class="text-xs font-medium text-n-ruby-11 mb-1"
        >
          {{
            $t('CRM_PIPELINE.DEAL.DAYS_OVERDUE', {
              count: daysOverdue(task.due_at),
            })
          }}
        </p>
        <div class="flex items-start gap-2">
          <span
            class="size-4 shrink-0 mt-0.5 text-n-slate-10"
            :class="taskTypeIcon[task.task_type] || taskTypeIcon.other"
          />
          <div class="min-w-0 flex-1">
            <p class="text-sm font-medium text-n-slate-12">
              {{ task.title }}
            </p>
            <div class="flex items-center gap-2 mt-1">
              <Avatar
                v-if="task.assigned_user"
                :name="task.assigned_user.name"
                :size="20"
                rounded-full
              />
              <span
                v-if="formatDue(task.due_at)"
                class="text-xs text-n-slate-11"
              >
                {{ formatDue(task.due_at) }}
              </span>
            </div>
            <button
              type="button"
              class="mt-2 text-xs text-n-blue-11 hover:underline"
              @click="emit('complete', task)"
            >
              {{ $t('CRM_PIPELINE.TASKS.COMPLETE') }}
            </button>
          </div>
        </div>
      </li>
    </ul>

    <p v-else class="text-xs text-n-slate-11">
      {{ $t('CRM_PIPELINE.DEAL.NO_PLANNED_ACTIVITIES') }}
    </p>
  </section>
</template>
