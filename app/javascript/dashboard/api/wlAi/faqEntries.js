/* global axios */
import ApiClient from '../ApiClient';

export class WlAiFaqEntriesClient extends ApiClient {
  constructor(assistantId) {
    super(`wl_ai/assistants/${assistantId}/faq_entries`, {
      accountScoped: true,
    });
    this.assistantId = assistantId;
  }

  index() {
    return axios.get(this.url);
  }

  create(payload) {
    return axios.post(this.url, { faq_entry: payload });
  }

  updateEntry(id, payload) {
    return axios.patch(`${this.url}/${id}`, { faq_entry: payload });
  }

  deleteEntry(id) {
    return axios.delete(`${this.url}/${id}`);
  }
}
