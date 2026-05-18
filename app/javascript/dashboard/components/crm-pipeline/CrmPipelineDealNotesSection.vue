<script setup>
import { reactive, computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { useStore, useMapGetter } from 'dashboard/composables/store';
import { useKeyboardEvents } from 'dashboard/composables/useKeyboardEvents';
import { useAdmin } from 'dashboard/composables/useAdmin';
import { useCrmNotePresentation } from 'dashboard/composables/useCrmNotePresentation';
import Editor from 'dashboard/components-next/Editor/Editor.vue';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import CrmPipelineDealNoteItem from './CrmPipelineDealNoteItem.vue';
import CrmPipelineDealPanelCard from './CrmPipelineDealPanelCard.vue';

const props = defineProps({
  dealId: { type: Number, required: true },
});

const { t } = useI18n();
const store = useStore();
const { authorLabel } = useCrmNotePresentation();

const state = reactive({
  message: '',
});

const { isAdmin } = useAdmin();
const currentUser = useMapGetter('getCurrentUser');
const dealNotes = useMapGetter('crmPipeline/getDealNotes');
const uiFlags = useMapGetter('crmPipeline/getUIFlags');

const notesList = computed(() => dealNotes.value || []);
const isFetchingNotes = computed(() => uiFlags.value.isFetchingDealNotes);
const isCreatingNote = computed(() => uiFlags.value.isCreatingDealNote);
const hasNotes = computed(() => notesList.value.length > 0);

const getAuthorName = note => authorLabel(note, currentUser.value?.id);

const canDelete = note => {
  if (isAdmin.value) return true;
  if (!note?.user?.id || !currentUser.value?.id) return false;
  return note.user.id === currentUser.value.id;
};

const onAdd = async () => {
  const content = state.message?.trim();
  if (!content) return;
  await store.dispatch('crmPipeline/createDealNote', {
    dealId: props.dealId,
    content,
  });
  state.message = '';
  await store.dispatch('crmPipeline/fetchDealNotes', props.dealId);
};

const onDelete = noteId => {
  if (!noteId) return;
  store.dispatch('crmPipeline/deleteDealNote', {
    dealId: props.dealId,
    noteId,
  });
};

const keyboardEvents = {
  '$mod+Enter': {
    action: onAdd,
    allowOnFocusedInput: true,
  },
};
useKeyboardEvents(keyboardEvents);
</script>

<template>
  <CrmPipelineDealPanelCard :title="$t('CRM_PIPELINE.DEAL.NOTES')">
    <div class="flex flex-col gap-3">
      <Editor
        v-model="state.message"
        :placeholder="t('CRM_PIPELINE.DEAL.NOTES_PLACEHOLDER')"
        :show-character-count="false"
        class="[&>div]:!border-transparent [&>div]:px-3 [&>div]:py-3"
      />

      <div class="flex justify-end">
        <Button
          variant="link"
          color="blue"
          size="sm"
          :label="t('CRM_PIPELINE.DEAL.NOTES_SAVE')"
          class="hover:no-underline"
          :is-loading="isCreatingNote"
          :disabled="!state.message?.trim() || isCreatingNote"
          @click="onAdd"
        />
      </div>

      <div
        v-if="isFetchingNotes"
        class="flex items-center justify-center py-8 text-n-slate-11"
      >
        <Spinner />
      </div>
      <div
        v-else-if="hasNotes"
        class="mt-2 divide-y divide-n-weak border-t border-n-weak"
      >
        <CrmPipelineDealNoteItem
          v-for="note in notesList"
          :key="note.id"
          :note="note"
          :author-name="getAuthorName(note)"
          :can-delete="canDelete(note)"
          @delete="onDelete"
        />
      </div>
      <p
        v-else-if="!isFetchingNotes"
        class="mt-2 border-t border-n-weak pt-4 text-sm text-n-slate-11"
      >
        {{ t('CRM_PIPELINE.DEAL.NOTES_EMPTY') }}
      </p>
    </div>
  </CrmPipelineDealPanelCard>
</template>
