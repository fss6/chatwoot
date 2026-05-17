import { frontendURL } from '../../../helper/URLHelper';
import { FEATURE_FLAGS } from '../../../featureFlags';

import DealsKanban from './pages/DealsKanban.vue';
import DealShow from './pages/DealShow.vue';
import TasksIndex from './pages/TasksIndex.vue';
import PipelineSettings from './pages/PipelineSettings.vue';

const commonMeta = {
  featureFlag: FEATURE_FLAGS.CRM_PIPELINE,
  permissions: ['administrator', 'agent'],
};

export const routes = [
  {
    path: frontendURL('accounts/:accountId/crm'),
    redirect: to => ({
      name: 'crm_pipeline_deals',
      params: { accountId: to.params.accountId },
    }),
  },
  {
    path: frontendURL('accounts/:accountId/crm/deals'),
    name: 'crm_pipeline_deals',
    component: DealsKanban,
    meta: commonMeta,
  },
  {
    path: frontendURL('accounts/:accountId/crm/deals/:dealId'),
    name: 'crm_pipeline_deal_show',
    component: DealShow,
    meta: commonMeta,
  },
  {
    path: frontendURL('accounts/:accountId/crm/tasks'),
    name: 'crm_pipeline_tasks',
    component: TasksIndex,
    meta: commonMeta,
  },
  {
    path: frontendURL('accounts/:accountId/crm/settings/pipelines'),
    name: 'crm_pipeline_settings',
    component: PipelineSettings,
    meta: { ...commonMeta, permissions: ['administrator'] },
  },
];
