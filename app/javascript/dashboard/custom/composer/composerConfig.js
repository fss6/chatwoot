/**
 * Composer AI — configuração do fork (white-label).
 *
 * Controla qual stack de IA aparece no reply box sem editar lógica upstream
 * além do patch em ReplyBox (quando implementado).
 *
 * Ver CUSTOMIZATIONS.md → "Mapa: IA no composer".
 */
export const composerConfig = {
  /**
   * Menu sparkle + tasks via Wl AI (`wl_ai/composer_tasks`, composable fork).
   * Requer implementação das fases A1+ em CUSTOMIZATIONS.md.
   */
  useWlAiComposer: true,

  /**
   * Menu upstream (CopilotMenuBar + `/captain/tasks`).
   * Desligar quando `useWlAiComposer` estiver true.
   */
  useCaptainTasks: false,

  /** Botão sparkle no ReplyTopPanel (Wl AI vs Captain upstream). */
  wlAiTriggerIcon: 'i-lucide-sparkles',
  captainTriggerIcon: 'i-ph-sparkle-fill',
};

/**
 * @returns {boolean} Exibir ações de IA do upstream no composer.
 */
export function isCaptainTasksComposerEnabled() {
  return composerConfig.useCaptainTasks && !composerConfig.useWlAiComposer;
}

/**
 * @returns {boolean} Exibir ações de IA Wl AI no composer (quando implementado).
 */
export function isWlAiComposerEnabled() {
  return composerConfig.useWlAiComposer;
}

/** @returns {string} Ícone do botão de IA no composer. */
export function getComposerTriggerIcon() {
  return isWlAiComposerEnabled()
    ? composerConfig.wlAiTriggerIcon
    : composerConfig.captainTriggerIcon;
}
