import { INSTALLATION_TYPES } from 'dashboard/constants/installationTypes';
import { frontendURL } from '../../helper/URLHelper';

const WlBotFlowsLayout = () => import('./WlBotFlowsLayout.vue');
const WlBotFlowsIndex = () => import('./pages/WlBotFlowsIndex.vue');
const WlBotFlowEditor = () => import('./pages/WlBotFlowEditor.vue');
const WlBotFlowLogs = () => import('./pages/WlBotFlowLogs.vue');

const meta = {
  permissions: ['administrator'],
  installationTypes: [
    INSTALLATION_TYPES.COMMUNITY,
    INSTALLATION_TYPES.CLOUD,
    INSTALLATION_TYPES.ENTERPRISE,
  ],
};

export const routes = [
  {
    path: frontendURL('accounts/:accountId/wl-bot-flows'),
    component: WlBotFlowsLayout,
    redirect: to => ({
      name: 'wl_bot_flows_index',
      params: { accountId: to.params.accountId },
    }),
    children: [
      {
        path: '',
        name: 'wl_bot_flows_index',
        component: WlBotFlowsIndex,
        meta,
      },
      {
        path: ':flowId',
        name: 'wl_bot_flow_editor',
        component: WlBotFlowEditor,
        meta,
      },
      {
        path: ':flowId/logs',
        name: 'wl_bot_flow_logs',
        component: WlBotFlowLogs,
        meta,
      },
    ],
  },
];
