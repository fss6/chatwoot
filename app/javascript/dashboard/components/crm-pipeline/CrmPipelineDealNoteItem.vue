<script setup>
import { computed, ref, onMounted, useTemplateRef } from 'vue';
import { useI18n } from 'vue-i18n';
import { useToggle } from '@vueuse/core';
import { useMessageFormatter } from 'shared/composables/useMessageFormatter';
import Avatar from 'dashboard/components-next/avatar/Avatar.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import DropdownMenu from 'dashboard/components-next/dropdown-menu/DropdownMenu.vue';
import { useCrmNotePresentation } from 'dashboard/composables/useCrmNotePresentation';

const props = defineProps({
  note: { type: Object, required: true },
  authorName: { type: String, required: true },
  canDelete: { type: Boolean, default: false },
});

const emit = defineEmits(['delete']);

const { t } = useI18n();
const { formatMessage } = useMessageFormatter();
const { formatNoteTime } = useCrmNotePresentation();

const showMenu = ref(false);
const noteContentRef = useTemplateRef('noteContentRef');
const needsCollapse = ref(false);
const [isExpanded, toggleExpanded] = useToggle();

const relativeTime = computed(() => formatNoteTime(props.note.createdAt));

const menuItems = computed(() => [
  {
    label: t('CRM_PIPELINE.DEAL.NOTES_DELETE'),
    action: 'delete',
    value: 'delete',
    icon: 'i-lucide-trash-2',
  },
]);

const avatarSrc = computed(() =>
  props.note?.user?.name ? props.note.user.thumbnail : null
);

const handleMenuAction = ({ action }) => {
  showMenu.value = false;
  if (action === 'delete') {
    emit('delete', props.note.id);
  }
};

onMounted(() => {
  const threshold = 14 * 1.625 * 4;
  needsCollapse.value = noteContentRef.value?.clientHeight > threshold;
});
</script>

<template>
  <article class="group/note flex gap-3 py-4">
    <Avatar
      :name="note.user?.name || authorName"
      :src="avatarSrc"
      :size="32"
      rounded-full
      class="shrink-0"
    />

    <div class="min-w-0 flex-1">
      <div class="flex min-w-0 items-start justify-between gap-2">
        <p class="min-w-0 text-sm leading-5">
          <span class="font-medium text-n-slate-12">{{ authorName }}</span>
          <span class="text-n-slate-9" aria-hidden="true"> · </span>
          <span class="text-n-slate-11">{{ relativeTime }}</span>
        </p>

        <div
          v-if="canDelete"
          v-on-clickaway="() => (showMenu = false)"
          class="relative shrink-0"
        >
          <Button
            icon="i-lucide-ellipsis"
            color="slate"
            variant="ghost"
            size="xs"
            :class="
              showMenu
                ? 'bg-n-alpha-2'
                : 'opacity-0 group-hover/note:opacity-100'
            "
            :aria-label="t('CRM_PIPELINE.DEAL.NOTES_ACTIONS')"
            @click="showMenu = !showMenu"
          />
          <DropdownMenu
            v-if="showMenu"
            :menu-items="menuItems"
            class="mt-1 w-40 ltr:right-0 rtl:left-0 top-full z-10"
            @action="handleMenuAction"
          />
        </div>
      </div>

      <div
        ref="noteContentRef"
        v-dompurify-html="formatMessage(note.content || '')"
        class="mt-1.5 text-sm leading-relaxed text-n-slate-12 prose-sm prose-p:my-0 prose-p:text-sm prose-p:leading-relaxed prose-ul:my-1 prose-ul:list-disc prose-ul:pl-4 prose-strong:font-semibold max-w-none"
        :class="{
          'line-clamp-4': needsCollapse && !isExpanded,
        }"
      />

      <Button
        v-if="needsCollapse"
        variant="faded"
        color="blue"
        size="xs"
        class="mt-2"
        :icon="isExpanded ? 'i-lucide-chevron-up' : 'i-lucide-chevron-down'"
        :label="
          isExpanded
            ? t('CRM_PIPELINE.DEAL.NOTES_COLLAPSE')
            : t('CRM_PIPELINE.DEAL.NOTES_EXPAND')
        "
        @click="toggleExpanded()"
      />
    </div>
  </article>
</template>
