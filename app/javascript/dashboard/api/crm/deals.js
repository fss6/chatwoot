/* global axios */
import ApiClient from '../ApiClient';

class CrmDealsAPI extends ApiClient {
  constructor() {
    super('crm/deals', { accountScoped: true });
  }

  get(params = {}) {
    return axios.get(this.url, { params });
  }

  move(id, { stageId, position }) {
    return axios.post(`${this.url}/${id}/move`, {
      stage_id: stageId,
      position,
    });
  }

  win(id) {
    return axios.post(`${this.url}/${id}/win`);
  }

  lose(id, lostReason) {
    return axios.post(`${this.url}/${id}/lose`, { lost_reason: lostReason });
  }

  archive(id) {
    return axios.post(`${this.url}/${id}/archive`);
  }

  getActivities(dealId) {
    return axios.get(`${this.url}/${dealId}/activities`);
  }

  getLabels(dealId) {
    return axios.get(`${this.url}/${dealId}/labels`);
  }

  updateLabels(dealId, labels) {
    return axios.post(`${this.url}/${dealId}/labels`, { labels });
  }
}

export default new CrmDealsAPI();
