import types from '../mutation-types';
import CrmDealsAPI from '../../api/crm/deals';

const state = {
  records: {},
  uiFlags: {
    isFetching: false,
    isUpdating: false,
    isError: false,
  },
};

export const getters = {
  getUIFlags: $state => $state.uiFlags,
  getDealLabels: $state => id => $state.records[Number(id)] || [],
};

export const actions = {
  get: async ({ commit }, dealId) => {
    commit(types.SET_DEAL_LABELS_UI_FLAG, { isFetching: true });
    try {
      const response = await CrmDealsAPI.getLabels(dealId);
      commit(types.SET_DEAL_LABELS, {
        id: dealId,
        data: response.data.payload,
      });
    } finally {
      commit(types.SET_DEAL_LABELS_UI_FLAG, { isFetching: false });
    }
  },
  set: ({ commit }, { dealId, labels }) => {
    commit(types.SET_DEAL_LABELS, {
      id: dealId,
      data: labels || [],
    });
  },
  update: async ({ commit, dispatch }, { dealId, labels, pipelineId }) => {
    commit(types.SET_DEAL_LABELS_UI_FLAG, { isUpdating: true });
    try {
      const response = await CrmDealsAPI.updateLabels(dealId, labels);
      const payload = response.data.payload;
      commit(types.SET_DEAL_LABELS, { id: dealId, data: payload });
      dispatch(
        'crmPipeline/syncDealLabels',
        { dealId, labels: payload, pipelineId },
        { root: true }
      );
      commit(types.SET_DEAL_LABELS_UI_FLAG, {
        isUpdating: false,
        isError: false,
      });
      return payload;
    } catch (error) {
      commit(types.SET_DEAL_LABELS_UI_FLAG, {
        isUpdating: false,
        isError: true,
      });
      throw error;
    }
  },
};

export const mutations = {
  [types.SET_DEAL_LABELS_UI_FLAG]($state, data) {
    $state.uiFlags = { ...$state.uiFlags, ...data };
  },
  [types.SET_DEAL_LABELS]: ($state, { id, data }) => {
    $state.records = {
      ...$state.records,
      [Number(id)]: data,
    };
  },
};

export default {
  namespaced: true,
  state,
  getters,
  actions,
  mutations,
};
