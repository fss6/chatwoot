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
    return axios.patch(this.url, { wl_ai_account_credential: data });
  }

  ping() {
    return axios.post(`${this.url}/ping`);
  }
}

export default new WlAiCredential();
