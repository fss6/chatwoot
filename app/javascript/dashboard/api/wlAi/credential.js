/* global axios */
import ApiClient from '../ApiClient';

class WlAiCredential extends ApiClient {
  constructor() {
    super('wl_ai/credential', { accountScoped: true });
  }

  show() {
    return axios.get(this.url);
  }

  update(data) {
    return axios.patch(this.url, data);
  }

  ping() {
    return axios.post(`${this.url}/ping`);
  }
}

export default new WlAiCredential();
