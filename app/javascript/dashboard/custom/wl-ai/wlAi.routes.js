import { INSTALLATION_TYPES } from 'dashboard/constants/installationTypes';
import { frontendURL } from '../../helper/URLHelper';

/**
 * Fork AI routes (MIT) — separate from Captain/Enterprise.
 * Assistants, per-assistant FAQs and playground; account-level credential on Settings.
 */
import WlAiLayout from './WlAiLayout.vue';
import WlAiSettings from './pages/WlAiSettings.vue';
import WlAiAssistantsIndex from './pages/WlAiAssistantsIndex.vue';
import WlAiFaqsIndex from './pages/WlAiFaqsIndex.vue';
import WlAiFaqsAssistantPicker from './pages/WlAiFaqsAssistantPicker.vue';
import WlAiPlayground from './pages/WlAiPlayground.vue';
import WlAiPlaygroundAssistantPicker from './pages/WlAiPlaygroundAssistantPicker.vue';

const wlAiMeta = {
  permissions: ['administrator'],
  installationTypes: [
    INSTALLATION_TYPES.COMMUNITY,
    INSTALLATION_TYPES.CLOUD,
    INSTALLATION_TYPES.ENTERPRISE,
  ],
};

// Paths must be relative to the parent so :accountId and :assistantId are merged
// into route.params (absolute /app/... child paths break param inheritance).
const wlAiChildRoutes = [
  {
    path: 'assistants',
    name: 'wl_ai_assistants_index',
    component: WlAiAssistantsIndex,
    meta: wlAiMeta,
  },
  {
    path: 'settings',
    name: 'wl_ai_settings_index',
    component: WlAiSettings,
    meta: wlAiMeta,
  },
  {
    path: 'faqs',
    name: 'wl_ai_faqs_pick',
    component: WlAiFaqsAssistantPicker,
    meta: wlAiMeta,
  },
  {
    path: 'playground',
    name: 'wl_ai_playground_pick',
    component: WlAiPlaygroundAssistantPicker,
    meta: wlAiMeta,
  },
  {
    path: ':assistantId/faqs',
    name: 'wl_ai_faqs_index',
    component: WlAiFaqsIndex,
    meta: wlAiMeta,
  },
  {
    path: ':assistantId/playground',
    name: 'wl_ai_playground_index',
    component: WlAiPlayground,
    meta: wlAiMeta,
  },
];

export const routes = [
  {
    path: frontendURL('accounts/:accountId/wl-ai'),
    component: WlAiLayout,
    redirect: to => ({
      name: 'wl_ai_assistants_index',
      params: { accountId: to.params.accountId },
    }),
    children: [...wlAiChildRoutes],
  },
];
