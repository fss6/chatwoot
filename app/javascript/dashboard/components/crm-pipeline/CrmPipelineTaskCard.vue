<script setup>
import { computed } from 'vue';
import { useCrmTaskPresentation } from 'dashboard/composables/useCrmTaskPresentation';

const props = defineProps({
  task: { type: Object, required: true },
});

const emit = defineEmits(['complete', 'cancel', 'edit']);

const { dueStatusLabel, taskTypeIcon, taskTypeLabel, getTaskDueTone } =
  useCrmTaskPresentation();

const tone = computed(() =>
  getTaskDueTone(props.task.due_at, props.task.is_overdue)
);

const statusLabel = computed(() =>
  dueStatusLabel(props.task.due_at, props.task.is_overdue)
);

const description = computed(() => props.task.description?.trim() || '');

const metaLine = computed(() => {
  const type = taskTypeLabel(props.task.task_type);
  const assignee = props.task.assigned_user?.name;
  if (assignee) {
    return { assignee, type };
  }
  return { assignee: null, type };
});
</script>

<template>
  <article class="flex border-l-4" :class="tone.border">
    <div class="flex min-w-0 flex-1 gap-3 px-5 py-4">
      <div
        class="flex size-10 shrink-0 items-center justify-center rounded-xl"
        :class="tone.iconBox"
      >
        <span
          class="size-5"
          :class="[taskTypeIcon(task.task_type), tone.icon]"
          aria-hidden="true"
        />
      </div>
      <div class="flex min-w-0 flex-1 gap-3">
        <div class="min-w-0 flex-1">
          <p class="text-sm font-semibold text-n-slate-12">
            {{ task.title }}
          </p>
          <p class="mt-0.5 text-xs text-n-slate-11">
            <template v-if="metaLine.assignee">
              {{ metaLine.assignee }}
              <span class="text-n-slate-9" aria-hidden="true">{{
                $t('CRM_PIPELINE.TASKS.META_SEPARATOR')
              }}</span>
              {{ metaLine.type }}
            </template>
            <template v-else>
              {{ metaLine.type }}
            </template>
          </p>
          <p
            v-if="description"
            class="mt-1 text-xs text-n-slate-11 line-clamp-2"
          >
            {{ description }}
          </p>
          <div class="mt-2.5 flex flex-wrap items-center gap-x-4 gap-y-1">
            <button
              type="button"
              class="inline-flex items-center gap-1 text-xs text-n-slate-11 transition-colors hover:text-n-slate-12"
              @click="emit('complete', task)"
            >
              <span class="i-lucide-check size-3.5" aria-hidden="true" />
              {{ $t('CRM_PIPELINE.TASKS.MARK_COMPLETE') }}
            </button>
            <button
              type="button"
              class="inline-flex items-center gap-1 text-xs text-n-slate-11 transition-colors hover:text-n-slate-12"
              @click="emit('edit', task)"
            >
              <span class="i-lucide-pencil size-3.5" aria-hidden="true" />
              {{ $t('CRM_PIPELINE.TASKS.EDIT_ACTION') }}
            </button>
            <button
              type="button"
              class="inline-flex items-center gap-1 text-xs text-n-slate-11 transition-colors hover:text-n-slate-12"
              @click="emit('cancel', task)"
            >
              <span class="i-lucide-x size-3.5" aria-hidden="true" />
              {{ $t('CRM_PIPELINE.TASKS.CANCEL_ACTION') }}
            </button>
          </div>
        </div>

        <p
          v-if="statusLabel"
          class="shrink-0 max-w-[7.5rem] text-right text-xs font-medium leading-snug"
          :class="tone.text"
        >
          {{ statusLabel }}
        </p>
      </div>
    </div>
  </article>
</template>
