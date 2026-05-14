/* global axios */
import ApiClient from '../ApiClient';

class WlAiAssistants extends ApiClient {
  constructor() {
    super('wl_ai/assistants', { accountScoped: true });
  }

  index() {
    return axios.get(this.url);
  }

  show(id) {
    return axios.get(`${this.url}/${id}`);
  }

  create(payload) {
    return axios.post(this.url, { assistant: payload });
  }

  update(id, payload) {
    return axios.patch(`${this.url}/${id}`, { assistant: payload });
  }

  delete(id) {
    return axios.delete(`${this.url}/${id}`);
  }
}

export default new WlAiAssistants();
