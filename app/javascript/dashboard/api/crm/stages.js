import ApiClient from '../ApiClient';

class CrmStagesAPI extends ApiClient {
  constructor() {
    super('crm/stages', { accountScoped: true });
  }
}

export default new CrmStagesAPI();
