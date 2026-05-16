/* global axios */
import ApiClient from '../ApiClient';

class WlAiComposerTasksAPI extends ApiClient {
  constructor() {
    super('wl_ai/composer', { accountScoped: true });
  }

  replySuggestion(conversationDisplayId, signal) {
    return axios.post(
      `${this.url}/reply_suggestion`,
      { conversation_display_id: conversationDisplayId },
      { signal }
    );
  }

  summarize(conversationDisplayId, signal) {
    return axios.post(
      `${this.url}/summarize`,
      { conversation_display_id: conversationDisplayId },
      { signal }
    );
  }

  rewrite({ content, operation, conversationDisplayId }, signal) {
    return axios.post(
      `${this.url}/rewrite`,
      {
        content,
        operation,
        conversation_display_id: conversationDisplayId,
      },
      { signal }
    );
  }
}

export default new WlAiComposerTasksAPI();
