/* global axios */
import ApiClient from '../ApiClient';

class CrmTasksAPI extends ApiClient {
  constructor() {
    super('crm/tasks', { accountScoped: true });
  }

  get(params = {}) {
    return axios.get(this.url, { params });
  }

  complete(id) {
    return axios.post(`${this.url}/${id}/complete`);
  }

  cancel(id) {
    return axios.post(`${this.url}/${id}/cancel`);
  }
}

export default new CrmTasksAPI();
