import { isWlAiComposerEnabled } from 'dashboard/custom/composer/composerConfig';
import { useCopilotReply } from 'dashboard/composables/useCopilotReply';
import { useWlAiComposer } from 'dashboard/composables/useWlAiComposer';

/**
 * Single entry point for reply-box AI assist (Captain Tasks vs Wl AI composer).
 */
export function useComposerAssist() {
  const captain = useCopilotReply();
  const wlAi = useWlAiComposer();

  return isWlAiComposerEnabled() ? wlAi : captain;
}
