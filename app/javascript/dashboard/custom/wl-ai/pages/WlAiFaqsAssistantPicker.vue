<script setup>
import { ref, computed, onMounted, nextTick, defineOptions } from 'vue';
import { useRouter } from 'vue-router';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import { useAccount } from 'dashboard/composables/useAccount';
import wlAiAssistants from 'dashboard/api/wlAi/assistants';
import {
  getWlAiLastAssistantId,
  setWlAiLastAssistantId,
} from 'dashboard/custom/wl-ai/composables/useWlAiNavigation';

import Dialog from 'dashboard/components-next/dialog/Dialog.vue';
import Select from 'dashboard/components-next/select/Select.vue';

defineOptions({
  name: 'WlAiFaqsAssistantPicker',
});

const { t } = useI18n();
const router = useRouter();
const { accountId, accountScopedRoute } = useAccount();

const dialogRef = ref(null);
const assistants = ref([]);
const selectedAssistantId = ref('');
const isLoading = ref(true);
const isSubmitting = ref(false);
const skipCloseNavigation = ref(false);

const assistantsListRoute = computed(() =>
  accountScopedRoute('wl_ai_assistants_index')
);

const selectOptions = computed(() =>
  assistants.value.map(a => ({
    value: a.id,
    label: a.name?.trim() || t('WL_AI.FAQS_PICK.UNNAMED', { id: a.id }),
  }))
);

const initSelection = () => {
  const list = assistants.value;
  if (!list.length) {
    selectedAssistantId.value = '';
    return;
  }
  const lastRaw = getWlAiLastAssistantId(accountId.value);
  const last = lastRaw ? Number(lastRaw) : NaN;
  const match = list.find(a => Number(a.id) === last);
  if (match) {
    selectedAssistantId.value = match.id;
    return;
  }
  if (list.length === 1) {
    selectedAssistantId.value = list[0].id;
    return;
  }
  selectedAssistantId.value = '';
};

const load = async () => {
  isLoading.value = true;
  try {
    const { data } = await wlAiAssistants.index();
    assistants.value = Array.isArray(data) ? data : [];
    initSelection();
  } catch {
    useAlert(t('WL_AI.FAQS_PICK.LOAD_ERROR'));
    assistants.value = [];
    selectedAssistantId.value = '';
  } finally {
    isLoading.value = false;
    nextTick(() => dialogRef.value?.open());
  }
};

const goToFaqs = () => {
  const id = Number(selectedAssistantId.value);
  if (!Number.isFinite(id) || id <= 0) return;
  isSubmitting.value = true;
  skipCloseNavigation.value = true;
  dialogRef.value?.close();
  if (accountId.value) {
    setWlAiLastAssistantId(accountId.value, id);
  }
  router.push(
    accountScopedRoute('wl_ai_faqs_index', { assistantId: String(id) })
  );
};

const onDialogClose = () => {
  if (skipCloseNavigation.value) {
    skipCloseNavigation.value = false;
    return;
  }
  router.replace(assistantsListRoute.value);
};

onMounted(() => {
  load();
});
</script>

<template>
  <div
    class="flex w-full h-full min-h-0 items-center justify-center bg-n-surface-1"
  >
    <Dialog
      ref="dialogRef"
      type="edit"
      width="md"
      :title="t('WL_AI.FAQS_PICK.TITLE')"
      :description="t('WL_AI.FAQS_PICK.DESCRIPTION')"
      :confirm-button-label="t('WL_AI.FAQS_PICK.CONTINUE')"
      :cancel-button-label="t('WL_AI.FAQS_PICK.CANCEL')"
      :is-loading="isLoading"
      :disable-confirm-button="
        isLoading ||
        !assistants.length ||
        selectedAssistantId === '' ||
        selectedAssistantId === null ||
        isSubmitting
      "
      @confirm="goToFaqs"
      @close="onDialogClose"
    >
      <p
        v-if="!isLoading && !assistants.length"
        class="text-sm text-n-slate-11 mb-0"
      >
        {{ t('WL_AI.FAQS_PICK.EMPTY') }}
      </p>
      <div v-else-if="!isLoading" class="flex flex-col gap-1.5 w-full min-w-0">
        <span class="text-sm font-medium text-n-slate-12">
          {{ t('WL_AI.FAQS_PICK.ASSISTANT_LABEL') }}
        </span>
        <div class="w-full min-w-0 [&>div]:w-full">
          <Select
            v-model="selectedAssistantId"
            :options="selectOptions"
            :placeholder="t('WL_AI.FAQS_PICK.PLACEHOLDER')"
          />
        </div>
      </div>
    </Dialog>
  </div>
</template>
