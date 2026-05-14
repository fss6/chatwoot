<script setup>
import { computed, nextTick, onMounted, ref, watch, defineOptions } from 'vue';
import { useI18n } from 'vue-i18n';
import { useRoute, useRouter } from 'vue-router';
import { useStore } from 'vuex';
import { useAlert } from 'dashboard/composables';
import { useAccount } from 'dashboard/composables/useAccount';
import { usePolicy } from 'dashboard/composables/usePolicy';
import wlAiInboxes from 'dashboard/api/wlAi/inboxes';
import wlAiAssistants from 'dashboard/api/wlAi/assistants';
import { setWlAiLastAssistantId } from 'dashboard/custom/wl-ai/composables/useWlAiNavigation';

import WlAiPageShell from 'dashboard/custom/wl-ai/components/WlAiPageShell.vue';
import WlAiInboxCard from 'dashboard/custom/wl-ai/components/WlAiInboxCard.vue';
import WlAiConnectInboxDialog from 'dashboard/custom/wl-ai/components/WlAiConnectInboxDialog.vue';
import BackButton from 'dashboard/components/widgets/BackButton.vue';
import Button from 'dashboard/components-next/button/Button.vue';

defineOptions({
  name: 'WlAiInboxesIndex',
});

const { t } = useI18n();
const route = useRoute();
const router = useRouter();
const store = useStore();
const { accountId, accountScopedRoute } = useAccount();
const { checkPermissions } = usePolicy();

const assistant = ref(null);
const connectedInboxes = ref([]);
const occupiedInboxIds = ref([]);
const isLoading = ref(true);
const showConnectDialog = ref(false);
const connectDialogRef = ref(null);
const showDeleteConfirmationPopup = ref(false);
const inboxPendingDisconnect = ref(null);

const assistantId = computed(() => Number(route.params.assistantId));

const assistantsListUrl = computed(() =>
  accountScopedRoute('wl_ai_assistants_index')
);

const canAdmin = computed(() => checkPermissions(['administrator']));

const pageHeaderTitle = computed(() => {
  if (assistant.value?.name) {
    return t('WL_AI.INBOXES.TITLE_WITH_ASSISTANT', {
      name: assistant.value.name,
    });
  }
  return t('WL_AI.INBOXES.HEADER');
});

const load = async () => {
  const aid = assistantId.value;
  if (!Number.isFinite(aid) || aid <= 0) {
    router.replace(assistantsListUrl.value);
    return;
  }

  isLoading.value = true;
  try {
    const [{ data: a }, { data: inboxData }] = await Promise.all([
      wlAiAssistants.show(aid),
      wlAiInboxes.get({ assistantId: aid }),
    ]);
    assistant.value = a;
    connectedInboxes.value = Array.isArray(inboxData?.payload)
      ? inboxData.payload
      : [];
    occupiedInboxIds.value = Array.isArray(inboxData?.meta?.occupied_inbox_ids)
      ? inboxData.meta.occupied_inbox_ids.map(Number)
      : [];
    if (accountId.value) {
      setWlAiLastAssistantId(accountId.value, aid);
    }
  } catch {
    useAlert(t('WL_AI.INBOXES.LOAD_ERROR'));
    assistant.value = null;
    connectedInboxes.value = [];
    occupiedInboxIds.value = [];
    router.replace(assistantsListUrl.value);
  } finally {
    isLoading.value = false;
  }
};

const openConnect = () => {
  showConnectDialog.value = true;
  nextTick(() => connectDialogRef.value?.open());
};

const closeConnect = () => {
  showConnectDialog.value = false;
};

const onInboxConnected = async () => {
  closeConnect();
  await load();
};

const handleCardAction = ({ action, id }) => {
  if (action !== 'delete') return;
  const inbox = connectedInboxes.value.find(i => i.id === id);
  if (inbox) {
    inboxPendingDisconnect.value = inbox;
    showDeleteConfirmationPopup.value = true;
  }
};

const closeDeletePopup = () => {
  showDeleteConfirmationPopup.value = false;
  inboxPendingDisconnect.value = null;
};

const confirmDisconnect = async () => {
  const inbox = inboxPendingDisconnect.value;
  if (!inbox) {
    closeDeletePopup();
    return;
  }
  const aid = assistantId.value;
  closeDeletePopup();
  try {
    await wlAiInboxes.delete({ assistantId: aid, inboxId: inbox.id });
    useAlert(t('WL_AI.INBOXES.DELETE.SUCCESS_MESSAGE'));
    await load();
  } catch {
    useAlert(t('WL_AI.INBOXES.DELETE.ERROR_MESSAGE'));
  }
};

const disconnectMessageValue = computed(
  () => inboxPendingDisconnect.value?.name || ''
);

watch(
  () => route.params.assistantId,
  () => {
    load();
  }
);

onMounted(() => {
  store.dispatch('inboxes/get');
  load();
});
</script>

<template>
  <div class="flex flex-col w-full h-full min-h-0 text-n-slate-12">
    <div class="px-6 pt-4 shrink-0">
      <BackButton
        compact
        :back-url="assistantsListUrl"
        :button-label="t('WL_AI.INBOXES.BACK_TO_ASSISTANTS')"
      />
    </div>

    <WlAiPageShell
      class="flex-1 min-h-0"
      :header-title="pageHeaderTitle"
      :header-subtitle="t('WL_AI.INBOXES.DESCRIPTION')"
      :button-label="canAdmin ? t('WL_AI.INBOXES.ADD_NEW') : ''"
      :is-fetching="isLoading"
      :is-empty="!isLoading && connectedInboxes.length === 0"
      :show-know-more="false"
      @primary-click="openConnect"
    >
      <template #emptyState>
        <div class="flex flex-col items-center gap-3 py-16 text-center">
          <p class="text-n-slate-11 max-w-md">
            {{ t('WL_AI.INBOXES.EMPTY_STATE.SUBTITLE') }}
          </p>
          <Button
            v-if="canAdmin"
            :label="t('WL_AI.INBOXES.ADD_NEW')"
            icon="i-lucide-plus"
            size="sm"
            @click="openConnect"
          />
        </div>
      </template>

      <template #body>
        <div class="flex flex-col gap-3">
          <WlAiInboxCard
            v-for="inbox in connectedInboxes"
            :id="inbox.id"
            :key="inbox.id"
            :inbox="inbox"
            @action="handleCardAction"
          />
        </div>
      </template>
    </WlAiPageShell>

    <WlAiConnectInboxDialog
      v-if="showConnectDialog"
      ref="connectDialogRef"
      :assistant-id="assistantId"
      :occupied-inbox-ids="occupiedInboxIds"
      @connected="onInboxConnected"
      @close="closeConnect"
    />

    <woot-delete-modal
      v-model:show="showDeleteConfirmationPopup"
      :on-close="closeDeletePopup"
      :on-confirm="confirmDisconnect"
      :title="t('WL_AI.INBOXES.DELETE.TITLE')"
      :message="t('WL_AI.INBOXES.DELETE.DESCRIPTION')"
      :message-value="disconnectMessageValue"
      :confirm-text="t('WL_AI.INBOXES.DELETE.CONFIRM')"
      :reject-text="t('WL_AI.INBOXES.DELETE.CANCEL')"
    />
  </div>
</template>
