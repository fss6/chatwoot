import { ref, computed } from 'vue';
import { useRouter } from 'vue-router';
import { useMapGetter } from 'dashboard/composables/store';
import { useAlert } from 'dashboard/composables';
import { useI18n } from 'vue-i18n';
import WlAiComposerTasksAPI from 'dashboard/api/wlAi/composerTasks';

const REWRITE_ACTIONS = [
  'improve',
  'fix_spelling_grammar',
  'casual',
  'professional',
  'straightforward',
  'confident',
  'friendly',
];

/**
 * Agent-assist state for the reply composer (Wl AI fork).
 * Mirrors the surface API of useCopilotReply for ReplyBox integration.
 */
export function useWlAiComposer() {
  const { t } = useI18n();
  const router = useRouter();
  const currentChat = useMapGetter('getSelectedChat');
  const currentAccountId = useMapGetter('getCurrentAccountId');

  const showEditor = ref(false);
  const isGenerating = ref(false);
  const isContentReady = ref(false);
  const generatedContent = ref('');
  const followUpContext = ref(null);
  const abortController = ref(null);

  const conversationId = computed(() => currentChat.value?.id);

  const isActive = computed(() => showEditor.value || isGenerating.value);
  const isButtonDisabled = computed(
    () => isGenerating.value || !isContentReady.value
  );
  const editorTransitionKey = computed(() =>
    isActive.value ? 'wl-ai-composer' : 'rich'
  );

  function reset() {
    if (abortController.value) {
      abortController.value.abort();
      abortController.value = null;
    }
    showEditor.value = false;
    isGenerating.value = false;
    isContentReady.value = false;
    generatedContent.value = '';
    followUpContext.value = null;
  }

  function setContentReady() {
    isContentReady.value = true;
  }

  async function processAction(action, data, signal) {
    const id = conversationId.value;
    if (action === 'summarize') {
      const result = await WlAiComposerTasksAPI.summarize(id, signal);
      return result.data?.message || '';
    }
    if (action === 'reply_suggestion') {
      const result = await WlAiComposerTasksAPI.replySuggestion(id, signal);
      return result.data?.message || '';
    }
    if (REWRITE_ACTIONS.includes(action)) {
      const result = await WlAiComposerTasksAPI.rewrite(
        {
          content: data || '',
          operation: action,
          conversationDisplayId: id,
        },
        signal
      );
      return result.data?.message || '';
    }
    return '';
  }

  async function execute(action, data) {
    if (action === 'open_playground') {
      const accountId = currentAccountId.value;
      if (!accountId) return;

      router.push({
        name: 'wl_ai_playground_pick',
        params: { accountId },
        query: conversationId.value
          ? { conversationId: String(conversationId.value) }
          : {},
      });
      return;
    }

    reset();
    const requestController = new AbortController();
    abortController.value = requestController;
    isGenerating.value = true;
    isContentReady.value = false;

    try {
      const content = await processAction(
        action,
        data,
        requestController.signal
      );

      if (requestController.signal.aborted) return;

      generatedContent.value = content;
      if (content) {
        showEditor.value = true;
      } else {
        useAlert(t('WL_AI.COMPOSER.GENERATE_ERROR'));
      }
      isGenerating.value = false;
    } catch (error) {
      if (
        requestController.signal.aborted ||
        error?.name === 'AbortError' ||
        error?.name === 'CanceledError'
      ) {
        return;
      }
      const errorMessage =
        error.response?.data?.error || t('WL_AI.COMPOSER.GENERATE_ERROR');
      useAlert(errorMessage);
      isGenerating.value = false;
    } finally {
      if (abortController.value === requestController) {
        abortController.value = null;
      }
    }
  }

  async function sendFollowUp() {
    // Follow-up refinement is not implemented for Wl AI composer yet.
  }

  function accept() {
    const content = generatedContent.value;
    showEditor.value = false;
    generatedContent.value = '';
    followUpContext.value = null;
    return content;
  }

  return {
    showEditor,
    isGenerating,
    isContentReady,
    generatedContent,
    followUpContext,
    isActive,
    isButtonDisabled,
    editorTransitionKey,
    reset,
    setContentReady,
    execute,
    sendFollowUp,
    accept,
  };
}
