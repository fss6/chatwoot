<script setup>
import { computed, onMounted, ref, watch, defineOptions, nextTick } from 'vue';
import { useI18n } from 'vue-i18n';
import { useRoute, useRouter } from 'vue-router';
import { picoSearch } from '@scmmishra/pico-search';
import { useAlert } from 'dashboard/composables';
import { useAccount } from 'dashboard/composables/useAccount';
import { WlAiFaqEntriesClient } from 'dashboard/api/wlAi/faqEntries';
import wlAiAssistants from 'dashboard/api/wlAi/assistants';
import { setWlAiLastAssistantId } from 'dashboard/custom/wl-ai/composables/useWlAiNavigation';

import WlAiPageShell from 'dashboard/custom/wl-ai/components/WlAiPageShell.vue';
import WlAiFaqCard from 'dashboard/custom/wl-ai/components/WlAiFaqCard.vue';
import BackButton from 'dashboard/components/widgets/BackButton.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import Dialog from 'dashboard/components-next/dialog/Dialog.vue';
import Input from 'dashboard/components-next/input/Input.vue';
import Editor from 'dashboard/components-next/Editor/Editor.vue';

defineOptions({
  name: 'WlAiFaqsIndex',
});

const { t } = useI18n();
const route = useRoute();
const router = useRouter();
const { accountId, accountScopedRoute } = useAccount();

const assistant = ref(null);
const entries = ref([]);
const isLoading = ref(true);
const dialogRef = ref(null);
const editingId = ref(null);
const formQuestion = ref('');
const formAnswer = ref('');
const isSaving = ref(false);
const searchQuery = ref('');
const showDeleteConfirmationPopup = ref(false);
const activeEntry = ref({});

const assistantId = computed(() => Number(route.params.assistantId));

const assistantsListUrl = computed(() =>
  accountScopedRoute('wl_ai_assistants_index')
);

const faqClient = computed(() => {
  const id = assistantId.value;
  return Number.isFinite(id) && id > 0 ? new WlAiFaqEntriesClient(id) : null;
});

const resetForm = () => {
  editingId.value = null;
  formQuestion.value = '';
  formAnswer.value = '';
};

const answerHasText = html => {
  if (!html) return false;
  return (
    html
      .replace(/<[^>]*>/g, ' ')
      .replace(/&nbsp;/gi, ' ')
      .trim().length > 0
  );
};

const filteredEntries = computed(() => {
  const query = searchQuery.value.trim();
  if (!query) return entries.value;
  return picoSearch(entries.value, query, [
    { name: 'question', weight: 3 },
    'answer',
  ]);
});

const load = async () => {
  const aid = assistantId.value;
  if (!Number.isFinite(aid) || aid <= 0) {
    router.replace(assistantsListUrl.value);
    return;
  }

  isLoading.value = true;
  try {
    const [{ data: a }, { data: list }] = await Promise.all([
      wlAiAssistants.show(aid),
      faqClient.value.index(),
    ]);
    assistant.value = a;
    entries.value = Array.isArray(list) ? list : [];
    if (accountId.value) {
      setWlAiLastAssistantId(accountId.value, aid);
    }
  } catch {
    useAlert(t('WL_AI.FAQS.LOAD_ERROR'));
    assistant.value = null;
    entries.value = [];
    router.replace(assistantsListUrl.value);
  } finally {
    isLoading.value = false;
  }
};

const openCreate = () => {
  resetForm();
  nextTick(() => dialogRef.value?.open());
};

const openEdit = entry => {
  editingId.value = entry.id;
  formQuestion.value = entry.question;
  formAnswer.value = entry.answer || '';
  nextTick(() => dialogRef.value?.open());
};

const closeDialog = () => {
  dialogRef.value?.close();
};

const saveEntry = async () => {
  if (!faqClient.value) return;
  isSaving.value = true;
  try {
    const payload = {
      question: formQuestion.value,
      answer: formAnswer.value,
    };
    if (editingId.value) {
      await faqClient.value.updateEntry(editingId.value, payload);
      useAlert(t('WL_AI.FAQS.UPDATED'));
    } else {
      await faqClient.value.create(payload);
      useAlert(t('WL_AI.FAQS.CREATED'));
    }
    closeDialog();
    await load();
  } catch (error) {
    useAlert(
      error.response?.data?.error ||
        error.response?.data?.message ||
        t('WL_AI.FAQS.SAVE_ERROR')
    );
  } finally {
    isSaving.value = false;
  }
};

const openDeletePopup = entry => {
  showDeleteConfirmationPopup.value = true;
  activeEntry.value = entry;
};

const closeDeletePopup = () => {
  showDeleteConfirmationPopup.value = false;
};

const deleteEntry = async id => {
  if (!faqClient.value) return;
  try {
    await faqClient.value.deleteEntry(id);
    useAlert(t('WL_AI.FAQS.DELETED'));
    await load();
  } catch {
    useAlert(t('WL_AI.FAQS.DELETE_ERROR'));
  }
};

const confirmDeletion = () => {
  const id = activeEntry.value.id;
  closeDeletePopup();
  deleteEntry(id);
};

const deleteMessageValue = computed(() => {
  const q = activeEntry.value?.question || '';
  return q.length > 120 ? `${q.slice(0, 120)}…` : q;
});

const handleCardAction = ({ action, id }) => {
  const entry = entries.value.find(e => e.id === id);
  if (!entry) return;
  if (action === 'edit') openEdit(entry);
  if (action === 'delete') openDeletePopup(entry);
};

const pageHeaderTitle = computed(() => {
  if (assistant.value?.name) {
    return t('WL_AI.FAQS.TITLE_WITH_ASSISTANT', { name: assistant.value.name });
  }
  return t('WL_AI.FAQS.TITLE');
});

const headerSubtitle = computed(() => {
  if (!assistant.value?.name) return t('WL_AI.FAQS.DESCRIPTION');
  return t('WL_AI.FAQS.SCOPE_HINT');
});

const modalAssistantNote = computed(() => {
  const name = assistant.value?.name;
  if (!name) return '';
  return t('WL_AI.FAQS.MODAL_ASSISTANT_NOTE', { name });
});

watch(
  () => route.params.assistantId,
  () => {
    resetForm();
    load();
  }
);

onMounted(() => {
  load();
});
</script>

<template>
  <div class="flex flex-col w-full h-full min-h-0 text-n-slate-12">
    <div class="px-6 pt-4 shrink-0">
      <BackButton
        compact
        :back-url="assistantsListUrl"
        :button-label="t('WL_AI.FAQS.BACK_TO_ASSISTANTS')"
      />
    </div>

    <WlAiPageShell
      class="flex-1 min-h-0"
      :header-title="pageHeaderTitle"
      :header-subtitle="headerSubtitle"
      :button-label="t('WL_AI.FAQS.ADD')"
      :is-fetching="isLoading"
      :is-empty="!isLoading && entries.length === 0"
      :show-know-more="false"
      @primary-click="openCreate"
    >
      <template #search>
        <Input
          v-if="entries.length"
          v-model="searchQuery"
          type="search"
          :placeholder="t('WL_AI.FAQS.SEARCH_PLACEHOLDER')"
          class="w-56 min-w-0"
          size="sm"
        />
      </template>

      <template #emptyState>
        <div class="flex flex-col items-center gap-3 py-16 text-center">
          <p class="text-n-slate-11 max-w-md">
            {{ t('WL_AI.FAQS.EMPTY') }}
          </p>
          <Button
            :label="t('WL_AI.FAQS.ADD')"
            icon="i-lucide-plus"
            size="sm"
            @click="openCreate"
          />
        </div>
      </template>

      <template #body>
        <div class="flex flex-col gap-3">
          <p
            v-if="searchQuery.trim() && !filteredEntries.length"
            class="text-center text-n-slate-11 py-8"
          >
            {{ t('WL_AI.FAQS.NO_SEARCH_RESULTS') }}
          </p>
          <WlAiFaqCard
            v-for="entry in filteredEntries"
            :id="entry.id"
            :key="entry.id"
            :question="entry.question"
            :answer="entry.answer"
            :updated-at="entry.updated_at"
            @action="handleCardAction"
          />
        </div>
      </template>
    </WlAiPageShell>

    <Dialog
      ref="dialogRef"
      type="edit"
      width="2xl"
      :title="
        editingId ? t('WL_AI.FAQS.EDIT_TITLE') : t('WL_AI.FAQS.CREATE_TITLE')
      "
      :description="t('WL_AI.FAQS.MODAL_DESCRIPTION')"
      :confirm-button-label="t('WL_AI.FAQS.SAVE')"
      :cancel-button-label="t('WL_AI.FAQS.CANCEL')"
      :is-loading="isSaving"
      :disable-confirm-button="
        !formQuestion.trim() || !answerHasText(formAnswer) || isSaving
      "
      overflow-y-auto
      @confirm="saveEntry"
      @close="resetForm"
    >
      <div class="flex flex-col gap-4">
        <Input
          v-if="assistant?.name"
          :model-value="assistant.name"
          type="text"
          disabled
          :label="t('WL_AI.FAQS.ASSISTANT_FIELD_LABEL')"
          :message="modalAssistantNote"
        />
        <Input
          v-model="formQuestion"
          type="text"
          :label="t('WL_AI.FAQS.QUESTION_LABEL')"
          :placeholder="t('WL_AI.FAQS.QUESTION_PLACEHOLDER')"
        />
        <Editor
          v-model="formAnswer"
          :label="t('WL_AI.FAQS.ANSWER_LABEL')"
          :placeholder="t('WL_AI.FAQS.ANSWER_PLACEHOLDER')"
          :max-length="100_000"
          show-character-count
          :enable-canned-responses="false"
          :enable-captain-tools="false"
        />
      </div>
    </Dialog>

    <woot-delete-modal
      v-model:show="showDeleteConfirmationPopup"
      :on-close="closeDeletePopup"
      :on-confirm="confirmDeletion"
      :title="t('WL_AI.FAQS.DELETE_CONFIRM.TITLE')"
      :message="t('WL_AI.FAQS.DELETE_CONFIRM.MESSAGE')"
      :message-value="deleteMessageValue"
      :confirm-text="t('WL_AI.FAQS.DELETE_CONFIRM.YES')"
      :reject-text="t('WL_AI.FAQS.DELETE_CONFIRM.NO')"
    />
  </div>
</template>
