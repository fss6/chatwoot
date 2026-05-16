<script setup>
import { ref, computed } from 'vue';
import { useI18n } from 'vue-i18n';
import CopilotEditor from 'dashboard/components/widgets/WootWriter/CopilotEditor.vue';
import CaptainLoader from 'dashboard/components/widgets/conversation/copilot/CaptainLoader.vue';
import WlAiLoader from 'dashboard/custom/composer/WlAiLoader.vue';
import { isWlAiComposerEnabled } from 'dashboard/custom/composer/composerConfig';

const props = defineProps({
  showCopilotEditor: {
    type: Boolean,
    default: false,
  },
  isGeneratingContent: {
    type: Boolean,
    default: false,
  },
  generatedContent: {
    type: String,
    default: '',
  },
  placeholder: {
    type: String,
    default: '',
  },
});

const emit = defineEmits([
  'focus',
  'blur',
  'clearSelection',
  'contentReady',
  'send',
]);

const { t } = useI18n();

const generatingLabel = computed(() =>
  isWlAiComposerEnabled()
    ? t('WL_AI.COMPOSER.GENERATING')
    : t('CONVERSATION.REPLYBOX.COPILOT_THINKING')
);

const editorPlaceholder = computed(() => {
  if (props.placeholder) return props.placeholder;
  return isWlAiComposerEnabled()
    ? t('WL_AI.COMPOSER.FOLLOW_UP_PLACEHOLDER')
    : t('CONVERSATION.FOOTER.COPILOT_MSG_INPUT');
});

const copilotEditorContent = ref('');

const onFocus = () => {
  emit('focus');
};

const onBlur = () => {
  emit('blur');
};

const clearEditorSelection = () => {
  emit('clearSelection');
};

const onSend = () => {
  emit('send', copilotEditorContent.value);
  copilotEditorContent.value = '';
};
</script>

<template>
  <Transition
    mode="out-in"
    enter-active-class="transition-all duration-300 ease-out"
    enter-from-class="opacity-0 translate-y-2 scale-[0.98]"
    enter-to-class="opacity-100 translate-y-0 scale-100"
    leave-active-class="transition-all duration-200 ease-in"
    leave-from-class="opacity-100 translate-y-0 scale-100"
    leave-to-class="opacity-0 translate-y-2 scale-[0.98]"
    @after-enter="emit('contentReady')"
  >
    <CopilotEditor
      v-if="showCopilotEditor && !isGeneratingContent"
      key="copilot-editor"
      v-model="copilotEditorContent"
      class="copilot-editor"
      :placeholder="editorPlaceholder"
      :generated-content="generatedContent"
      :min-height="4"
      :enabled-menu-options="[]"
      @focus="onFocus"
      @blur="onBlur"
      @clear-selection="clearEditorSelection"
      @send="onSend"
    />
    <div
      v-else-if="isGeneratingContent"
      key="loading-state"
      class="rounded min-h-[4.75rem] w-full mb-4 p-4 flex items-start"
      :class="isWlAiComposerEnabled() ? 'bg-n-blue-3' : 'bg-n-iris-5'"
    >
      <div class="flex items-center gap-2">
        <WlAiLoader
          v-if="isWlAiComposerEnabled()"
          class="text-n-brand size-4"
        />
        <CaptainLoader v-else class="text-n-iris-10 size-4" />
        <span
          class="text-sm"
          :class="isWlAiComposerEnabled() ? 'text-n-blue-11' : 'text-n-iris-10'"
        >
          {{ generatingLabel }}
        </span>
      </div>
    </div>
  </Transition>
</template>

<style lang="scss">
.copilot-editor {
  .ProseMirror-menubar {
    display: none;
  }
}
</style>
