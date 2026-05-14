<script setup>
import { computed, nextTick, onMounted, ref, defineOptions } from 'vue';
import { useI18n } from 'vue-i18n';
import { useRouter } from 'vue-router';
import { useAlert } from 'dashboard/composables';
import { useAccount } from 'dashboard/composables/useAccount';
import wlAiAssistants from 'dashboard/api/wlAi/assistants';
import { setWlAiLastAssistantId } from 'dashboard/custom/wl-ai/composables/useWlAiNavigation';

import WlAiPageShell from 'dashboard/custom/wl-ai/components/WlAiPageShell.vue';
import WlAiAssistantCard from 'dashboard/custom/wl-ai/components/WlAiAssistantCard.vue';
import WlAiAssistantDialog from 'dashboard/custom/wl-ai/components/WlAiAssistantDialog.vue';
import Button from 'dashboard/components-next/button/Button.vue';

defineOptions({
  name: 'WlAiAssistantsIndex',
});

const { t } = useI18n();
const router = useRouter();
const { accountId } = useAccount();

const assistants = ref([]);
const isFetching = ref(true);
const dialogRef = ref(null);
const dialogMode = ref('create');
const selectedAssistant = ref(null);
const showDeleteConfirmationPopup = ref(false);
const assistantPendingDelete = ref(null);

const isEmpty = computed(
  () => !isFetching.value && assistants.value.length === 0
);

const load = async () => {
  isFetching.value = true;
  try {
    const { data } = await wlAiAssistants.index();
    assistants.value = Array.isArray(data) ? data : [];
  } catch {
    useAlert(t('WL_AI.ASSISTANTS.LOAD_ERROR'));
    assistants.value = [];
  } finally {
    isFetching.value = false;
  }
};

const openCreate = () => {
  dialogMode.value = 'create';
  selectedAssistant.value = null;
  nextTick(() => dialogRef.value?.open());
};

const openEdit = assistant => {
  dialogMode.value = 'edit';
  selectedAssistant.value = assistant;
  nextTick(() => dialogRef.value?.open());
};

const closeDialog = () => {
  dialogMode.value = '';
  selectedAssistant.value = null;
};

const handleSaved = async () => {
  await load();
};

const goToFaqs = assistantId => {
  if (accountId.value) {
    setWlAiLastAssistantId(accountId.value, assistantId);
  }
  router.push({
    name: 'wl_ai_faqs_index',
    params: {
      accountId: router.currentRoute.value.params.accountId,
      assistantId: String(assistantId),
    },
  });
};

const handleCardAction = ({ action, id }) => {
  const assistant = assistants.value.find(a => a.id === id);
  if (action === 'edit' && assistant) {
    openEdit(assistant);
  }
  if (action === 'delete' && assistant) {
    assistantPendingDelete.value = assistant;
    showDeleteConfirmationPopup.value = true;
  }
};

const closeDeletePopup = () => {
  showDeleteConfirmationPopup.value = false;
  assistantPendingDelete.value = null;
};

const confirmDeleteAssistant = async () => {
  const id = assistantPendingDelete.value?.id;
  if (!id) {
    closeDeletePopup();
    return;
  }
  closeDeletePopup();
  try {
    await wlAiAssistants.delete(id);
    useAlert(t('WL_AI.ASSISTANTS.DELETED'));
    await load();
  } catch {
    useAlert(t('WL_AI.ASSISTANTS.DELETE_ERROR'));
  }
};

const deleteMessageValue = computed(
  () => assistantPendingDelete.value?.name || ''
);

onMounted(() => {
  load();
});
</script>

<template>
  <WlAiPageShell
    :header-title="t('WL_AI.ASSISTANTS.TITLE')"
    :button-label="t('WL_AI.ASSISTANTS.ADD')"
    :is-fetching="isFetching"
    :is-empty="isEmpty"
    :show-know-more="false"
    @primary-click="openCreate"
  >
    <template #emptyState>
      <div
        class="flex flex-col items-center justify-center gap-4 py-16 text-center"
      >
        <p class="text-n-slate-11 max-w-md">
          {{ t('WL_AI.ASSISTANTS.EMPTY') }}
        </p>
        <Button
          :label="t('WL_AI.ASSISTANTS.ADD')"
          icon="i-lucide-plus"
          size="sm"
          @click="openCreate"
        />
      </div>
    </template>

    <template #body>
      <div class="flex flex-col gap-3">
        <WlAiAssistantCard
          v-for="a in assistants"
          :id="a.id"
          :key="a.id"
          :name="a.name"
          :description="a.description"
          :updated-at="a.updated_at"
          @open-faqs="goToFaqs"
          @action="handleCardAction"
        />
      </div>
    </template>

    <WlAiAssistantDialog
      v-if="dialogMode"
      ref="dialogRef"
      :mode="dialogMode"
      :assistant="selectedAssistant"
      @close="closeDialog"
      @saved="handleSaved"
    />

    <woot-delete-modal
      v-model:show="showDeleteConfirmationPopup"
      :on-close="closeDeletePopup"
      :on-confirm="confirmDeleteAssistant"
      :title="t('WL_AI.ASSISTANTS.DELETE_CONFIRM.TITLE')"
      :message="t('WL_AI.ASSISTANTS.DELETE_CONFIRM.MESSAGE')"
      :message-value="deleteMessageValue"
      :confirm-text="t('WL_AI.ASSISTANTS.DELETE_CONFIRM.YES')"
      :reject-text="t('WL_AI.ASSISTANTS.DELETE_CONFIRM.NO')"
    />
  </WlAiPageShell>
</template>
