/* global axios */
import ApiClient from '../ApiClient';

class WlBotFlowsApi extends ApiClient {
  constructor() {
    super('wl_bot_flows/flows', { accountScoped: true });
  }

  index() {
    return axios.get(this.url);
  }

  show(id) {
    return axios.get(`${this.url}/${id}`);
  }

  create(payload) {
    return axios.post(this.url, { flow: payload });
  }

  update(id, payload) {
    return axios.patch(`${this.url}/${id}`, { flow: payload });
  }

  destroy(id) {
    return axios.delete(`${this.url}/${id}`);
  }

  publish(id) {
    return axios.post(`${this.url}/${id}/publish`);
  }

  pause(id) {
    return axios.post(`${this.url}/${id}/pause`);
  }

  duplicate(id) {
    return axios.post(`${this.url}/${id}/duplicate`);
  }

  executionLogs(id, params = {}) {
    return axios.get(`${this.url}/${id}/execution_logs`, { params });
  }
}

export default new WlBotFlowsApi();
