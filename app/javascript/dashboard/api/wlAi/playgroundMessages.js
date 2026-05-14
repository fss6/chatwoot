/* global axios */
import ApiClient from '../ApiClient';

export class WlAiPlaygroundMessagesClient extends ApiClient {
  constructor(assistantId) {
    super(`wl_ai/assistants/${assistantId}/playground_messages`, {
      accountScoped: true,
    });
  }

  create(messages) {
    return axios.post(this.url, { playground: { messages } });
  }
}
