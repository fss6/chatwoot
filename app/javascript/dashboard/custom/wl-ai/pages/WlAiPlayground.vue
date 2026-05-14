<script setup>
import { ref, computed, watch, onMounted, nextTick, defineOptions } from 'vue';
import { useI18n } from 'vue-i18n';
import { useRoute, useRouter } from 'vue-router';
import { useAlert } from 'dashboard/composables';
import { useAccount } from 'dashboard/composables/useAccount';
import wlAiAssistants from 'dashboard/api/wlAi/assistants';
import { WlAiPlaygroundMessagesClient } from 'dashboard/api/wlAi/playgroundMessages';
import { setWlAiLastAssistantId } from 'dashboard/custom/wl-ai/composables/useWlAiNavigation';

import WlAiPageShell from 'dashboard/custom/wl-ai/components/WlAiPageShell.vue';
import BackButton from 'dashboard/components/widgets/BackButton.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import TextArea from 'dashboard/components-next/textarea/TextArea.vue';

defineOptions({
  name: 'WlAiPlayground',
});

const { t } = useI18n();
const route = useRoute();
const router = useRouter();
const { accountId, accountScopedRoute } = useAccount();

const assistant = ref(null);
const messages = ref([]);
const draft = ref('');
const isLoadingAssistant = ref(true);
const isSending = ref(false);
const lastUsage = ref(null);
const lastModel = ref(null);
const chatEndRef = ref(null);

const assistantId = computed(() => Number(route.params.assistantId));

const assistantsListUrl = computed(() =>
  accountScopedRoute('wl_ai_assistants_index')
);

const playgroundClient = computed(() => {
  const id = assistantId.value;
  return Number.isFinite(id) && id > 0
    ? new WlAiPlaygroundMessagesClient(id)
    : null;
});

const pageHeaderTitle = computed(() => {
  if (assistant.value?.name) {
    return t('WL_AI.PLAYGROUND.TITLE_WITH_ASSISTANT', {
      name: assistant.value.name,
    });
  }
  return t('WL_AI.PLAYGROUND.TITLE');
});

const scrollToBottom = () => {
  nextTick(() => {
    chatEndRef.value?.scrollIntoView({ behavior: 'smooth', block: 'end' });
  });
};

const loadAssistant = async () => {
  const aid = assistantId.value;
  if (!Number.isFinite(aid) || aid <= 0) {
    router.replace(assistantsListUrl.value);
    return;
  }

  isLoadingAssistant.value = true;
  try {
    const { data } = await wlAiAssistants.show(aid);
    assistant.value = data;
    if (accountId.value) {
      setWlAiLastAssistantId(accountId.value, aid);
    }
  } catch {
    useAlert(t('WL_AI.PLAYGROUND.LOAD_ASSISTANT_ERROR'));
    assistant.value = null;
    router.replace(assistantsListUrl.value);
  } finally {
    isLoadingAssistant.value = false;
  }
};

const clearConversation = () => {
  messages.value = [];
  lastUsage.value = null;
  lastModel.value = null;
};

const sendMessage = async () => {
  const text = draft.value.trim();
  if (!text || isSending.value || !playgroundClient.value) return;

  isSending.value = true;
  const thread = [...messages.value, { role: 'user', content: text }];

  try {
    const { data } = await playgroundClient.value.create(thread);
    messages.value = [
      ...thread,
      { role: 'assistant', content: data.message || '' },
    ];
    lastUsage.value = data.usage || null;
    lastModel.value = data.model || null;
    draft.value = '';
    scrollToBottom();
  } catch (error) {
    useAlert(
      error.response?.data?.error ||
        error.response?.data?.message ||
        t('WL_AI.PLAYGROUND.SEND_ERROR')
    );
  } finally {
    isSending.value = false;
  }
};

watch(
  () => route.params.assistantId,
  () => {
    messages.value = [];
    lastUsage.value = null;
    lastModel.value = null;
    draft.value = '';
    loadAssistant();
  }
);

onMounted(() => {
  loadAssistant();
});
</script>

<template>
  <div class="flex flex-col w-full h-full min-h-0 text-n-slate-12">
    <div class="px-6 pt-4 shrink-0">
      <BackButton
        compact
        :back-url="assistantsListUrl"
        :button-label="t('WL_AI.PLAYGROUND.BACK_TO_ASSISTANTS')"
      />
    </div>

    <WlAiPageShell
      class="flex-1 min-h-0"
      :header-title="pageHeaderTitle"
      :header-subtitle="t('WL_AI.PLAYGROUND.INTRO')"
      :is-fetching="isLoadingAssistant"
      :is-empty="false"
      :show-know-more="false"
    >
      <template #body>
        <div
          class="flex flex-col gap-4 h-full min-h-[20rem] max-h-[calc(100vh-14rem)]"
        >
          <div class="flex items-center justify-between gap-2 shrink-0">
            <p class="text-sm text-n-slate-11 mb-0">
              {{ t('WL_AI.PLAYGROUND.HINT') }}
            </p>
            <Button
              v-if="messages.length"
              variant="faded"
              color="slate"
              size="sm"
              :label="t('WL_AI.PLAYGROUND.CLEAR')"
              @click="clearConversation"
            />
          </div>

          <div
            class="flex flex-col flex-1 min-h-0 gap-3 overflow-y-auto rounded-lg border border-n-weak bg-n-alpha-black2 p-4"
          >
            <p
              v-if="!messages.length"
              class="text-sm text-n-slate-11 mb-0 text-center py-8"
            >
              {{ t('WL_AI.PLAYGROUND.EMPTY_THREAD') }}
            </p>
            <div
              v-for="(m, i) in messages"
              :key="i"
              class="flex w-full"
              :class="m.role === 'user' ? 'justify-end' : 'justify-start'"
            >
              <div
                class="max-w-[min(85%,32rem)] rounded-lg px-3 py-2 text-sm whitespace-pre-wrap break-words"
                :class="
                  m.role === 'user'
                    ? 'bg-n-brand text-white'
                    : 'bg-n-solid-3 text-n-slate-12'
                "
              >
                {{ m.content }}
              </div>
            </div>
            <div ref="chatEndRef" class="h-px shrink-0" />
          </div>

          <div
            v-if="(lastUsage && lastUsage.total_tokens != null) || lastModel"
            class="flex flex-col gap-1 shrink-0"
          >
            <p
              v-if="lastUsage && lastUsage.total_tokens != null"
              class="text-xs text-n-slate-11 mb-0"
            >
              {{
                t('WL_AI.PLAYGROUND.USAGE', {
                  total: lastUsage.total_tokens,
                })
              }}
            </p>
            <p v-if="lastModel" class="text-xs text-n-slate-11 mb-0">
              {{ t('WL_AI.PLAYGROUND.MODEL_USED', { model: lastModel }) }}
            </p>
          </div>

          <div class="flex flex-col gap-2 shrink-0 pt-2 border-t border-n-weak">
            <TextArea
              v-model="draft"
              :label="t('WL_AI.PLAYGROUND.INPUT_LABEL')"
              :placeholder="t('WL_AI.PLAYGROUND.INPUT_PLACEHOLDER')"
              :max-length="12000"
              :disabled="isSending"
              auto-height
              resize
              @keydown.enter.exact.prevent="sendMessage"
            />
            <div class="flex justify-end">
              <Button
                :label="t('WL_AI.PLAYGROUND.SEND')"
                icon="i-lucide-send"
                size="sm"
                :is-loading="isSending"
                :disabled="!draft.trim() || isSending"
                @click="sendMessage"
              />
            </div>
          </div>
        </div>
      </template>
    </WlAiPageShell>
  </div>
</template>
