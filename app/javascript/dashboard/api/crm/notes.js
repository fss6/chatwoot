/* global axios */
import ApiClient from '../ApiClient';

class CrmDealNotesAPI extends ApiClient {
  constructor() {
    super('crm/deals', { accountScoped: true });
    this.dealId = null;
  }

  notesUrl() {
    return `${this.url}/${this.dealId}/notes`;
  }

  get(dealId) {
    this.dealId = dealId;
    return axios.get(this.notesUrl());
  }

  create(dealId, content) {
    this.dealId = dealId;
    return axios.post(this.notesUrl(), { note: { content } });
  }

  delete(dealId, noteId) {
    this.dealId = dealId;
    return axios.delete(`${this.notesUrl()}/${noteId}`);
  }
}

export default new CrmDealNotesAPI();
