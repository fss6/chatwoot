const storageKey = accountId => `wlAi:lastAssistantId:${accountId}`;

export function getWlAiLastAssistantId(accountId) {
  if (!accountId || typeof window === 'undefined') return null;
  try {
    return window.localStorage.getItem(storageKey(accountId));
  } catch {
    return null;
  }
}

export function setWlAiLastAssistantId(accountId, assistantId) {
  if (!accountId || !assistantId || typeof window === 'undefined') return;
  try {
    window.localStorage.setItem(storageKey(accountId), String(assistantId));
  } catch {
    // ignore quota / private mode
  }
}
