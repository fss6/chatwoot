import camelcaseKeys from 'camelcase-keys';
import CrmPipelinesAPI from '../../api/crm/pipelines';
import CrmDealsAPI from '../../api/crm/deals';
import CrmDealNotesAPI from '../../api/crm/notes';
import CrmTasksAPI from '../../api/crm/tasks';
import CrmStagesAPI from '../../api/crm/stages';
import { throwErrorMessage } from '../utils/api';

export const state = {
  pipelines: [],
  selectedPipelineId: null,
  deals: [],
  tasks: [],
  dealTasks: [],
  currentDeal: null,
  dealNotes: [],
  activities: [],
  uiFlags: {
    isFetchingPipelines: false,
    isFetchingDeals: false,
    isFetchingDeal: false,
    isFetchingTasks: false,
    isFetchingDealNotes: false,
    isCreatingDealNote: false,
    isDeletingDealNote: false,
    isSaving: false,
  },
};

export const getters = {
  getPipelines: $state => $state.pipelines,
  getSelectedPipeline: $state => {
    return (
      $state.pipelines.find(p => p.id === $state.selectedPipelineId) ||
      $state.pipelines[0]
    );
  },
  getStages: (_state, $getters) => $getters.getSelectedPipeline?.stages || [],
  getDeals: $state => $state.deals,
  getDealsByStage: $state => stageId => {
    return $state.deals
      .filter(d => d.stage.id === stageId)
      .sort((a, b) => a.position - b.position);
  },
  getTasks: $state => $state.tasks,
  getDealTasks: $state => $state.dealTasks,
  getCurrentDeal: $state => $state.currentDeal,
  getDealNotes: $state => $state.dealNotes,
  getActivities: $state => $state.activities,
  getUIFlags: $state => $state.uiFlags,
};

export const actions = {
  fetchPipelines: async ({ commit, state: storeState }) => {
    commit('SET_UI_FLAG', { isFetchingPipelines: true });
    try {
      const { data } = await CrmPipelinesAPI.get();
      const pipelines = data.payload || [];
      commit('SET_PIPELINES', pipelines);
      if (pipelines.length && !storeState.selectedPipelineId) {
        commit('SET_SELECTED_PIPELINE_ID', pipelines[0].id);
      }
    } catch (error) {
      throwErrorMessage(error);
    } finally {
      commit('SET_UI_FLAG', { isFetchingPipelines: false });
    }
  },

  fetchDeals: async ({ commit }, params = {}) => {
    commit('SET_UI_FLAG', { isFetchingDeals: true });
    try {
      const { data } = await CrmDealsAPI.get(params);
      commit('SET_DEALS', data.payload || []);
    } catch (error) {
      throwErrorMessage(error);
    } finally {
      commit('SET_UI_FLAG', { isFetchingDeals: false });
    }
  },

  fetchDeal: async ({ commit }, id) => {
    commit('SET_UI_FLAG', { isFetchingDeal: true });
    try {
      const { data } = await CrmDealsAPI.show(id);
      commit('SET_CURRENT_DEAL', data.payload);
      return data.payload;
    } catch (error) {
      throwErrorMessage(error);
      throw error;
    } finally {
      commit('SET_UI_FLAG', { isFetchingDeal: false });
    }
  },

  clearCurrentDeal: ({ commit }) => {
    commit('SET_CURRENT_DEAL', null);
    commit('SET_DEAL_TASKS', []);
    commit('SET_DEAL_NOTES', []);
  },

  fetchDealNotes: async ({ commit }, dealId) => {
    commit('SET_UI_FLAG', { isFetchingDealNotes: true });
    try {
      const { data } = await CrmDealNotesAPI.get(dealId);
      const notes = camelcaseKeys(data.payload || [], { deep: true });
      commit('SET_DEAL_NOTES', notes);
    } catch (error) {
      throwErrorMessage(error);
    } finally {
      commit('SET_UI_FLAG', { isFetchingDealNotes: false });
    }
  },

  createDealNote: async ({ commit }, { dealId, content }) => {
    commit('SET_UI_FLAG', { isCreatingDealNote: true });
    try {
      const { data } = await CrmDealNotesAPI.create(dealId, content);
      const note = camelcaseKeys(data.payload, { deep: true });
      commit('ADD_DEAL_NOTE', note);
    } catch (error) {
      throwErrorMessage(error);
      throw error;
    } finally {
      commit('SET_UI_FLAG', { isCreatingDealNote: false });
    }
  },

  deleteDealNote: async ({ commit }, { dealId, noteId }) => {
    commit('SET_UI_FLAG', { isDeletingDealNote: true });
    try {
      await CrmDealNotesAPI.delete(dealId, noteId);
      commit('REMOVE_DEAL_NOTE', noteId);
    } catch (error) {
      throwErrorMessage(error);
      throw error;
    } finally {
      commit('SET_UI_FLAG', { isDeletingDealNote: false });
    }
  },

  createDeal: async ({ commit, dispatch }, dealParams) => {
    commit('SET_UI_FLAG', { isSaving: true });
    try {
      const payload = {
        deal: {
          ...dealParams,
          contact_id: dealParams.contact_id || dealParams.contactId,
        },
      };
      const { data } = await CrmDealsAPI.create(payload);
      await dispatch('fetchDeals', { pipeline_id: dealParams.pipeline_id });
      return data.payload;
    } catch (error) {
      throwErrorMessage(error);
      throw error;
    } finally {
      commit('SET_UI_FLAG', { isSaving: false });
    }
  },

  moveDeal: async (
    { commit, dispatch, state: storeState },
    { id, stageId, position, pipelineId, refreshDeal = false }
  ) => {
    commit('SET_UI_FLAG', { isSaving: true });
    try {
      const { data } = await CrmDealsAPI.move(id, { stageId, position });
      if (refreshDeal || storeState.currentDeal?.id === id) {
        commit('SET_CURRENT_DEAL', data.payload);
      }
      await dispatch('fetchDeals', { pipeline_id: pipelineId });
      return data.payload;
    } catch (error) {
      throwErrorMessage(error);
      throw error;
    } finally {
      commit('SET_UI_FLAG', { isSaving: false });
    }
  },

  updateDeal: async (
    { commit, dispatch, state: storeState },
    { id, params, pipelineId, refreshDeal = false }
  ) => {
    commit('SET_UI_FLAG', { isSaving: true });
    try {
      const { data } = await CrmDealsAPI.update(id, { deal: params });
      if (refreshDeal || storeState.currentDeal?.id === id) {
        commit('SET_CURRENT_DEAL', data.payload);
      }
      if (pipelineId) {
        await dispatch('fetchDeals', { pipeline_id: pipelineId });
      }
      return data.payload;
    } catch (error) {
      throwErrorMessage(error);
      throw error;
    } finally {
      commit('SET_UI_FLAG', { isSaving: false });
    }
  },

  winDeal: async (
    { commit, dispatch, state: storeState },
    { id, pipelineId, refreshDeal = false }
  ) => {
    const { data } = await CrmDealsAPI.win(id);
    if (refreshDeal || storeState.currentDeal?.id === id) {
      commit('SET_CURRENT_DEAL', data.payload);
    }
    await dispatch('fetchDeals', { pipeline_id: pipelineId });
    return data.payload;
  },

  loseDeal: async (
    { commit, dispatch, state: storeState },
    { id, lostReason, pipelineId, refreshDeal = false }
  ) => {
    const { data } = await CrmDealsAPI.lose(id, lostReason);
    if (refreshDeal || storeState.currentDeal?.id === id) {
      commit('SET_CURRENT_DEAL', data.payload);
    }
    await dispatch('fetchDeals', { pipeline_id: pipelineId });
    return data.payload;
  },

  fetchTasks: async ({ commit }, params = {}) => {
    commit('SET_UI_FLAG', { isFetchingTasks: true });
    try {
      const { data } = await CrmTasksAPI.get(params);
      commit('SET_TASKS', data.payload || []);
    } catch (error) {
      throwErrorMessage(error);
    } finally {
      commit('SET_UI_FLAG', { isFetchingTasks: false });
    }
  },

  fetchDealTasks: async ({ commit }, dealId) => {
    if (!dealId) return;
    commit('SET_UI_FLAG', { isFetchingTasks: true });
    try {
      const { data } = await CrmTasksAPI.get({
        deal_id: dealId,
        status: 'pending',
      });
      commit('SET_DEAL_TASKS', data.payload || []);
    } catch (error) {
      throwErrorMessage(error);
    } finally {
      commit('SET_UI_FLAG', { isFetchingTasks: false });
    }
  },

  createTask: async ({ dispatch, commit }, { task, listParams, dealId }) => {
    commit('SET_UI_FLAG', { isSaving: true });
    try {
      const { data } = await CrmTasksAPI.create({ task });
      if (dealId) {
        await dispatch('fetchDealTasks', dealId);
      } else if (listParams) {
        await dispatch('fetchTasks', listParams);
      }
      return data.payload;
    } catch (error) {
      throwErrorMessage(error);
      throw error;
    } finally {
      commit('SET_UI_FLAG', { isSaving: false });
    }
  },

  updateTask: async (
    { dispatch, commit },
    { id, task, listParams, dealId }
  ) => {
    commit('SET_UI_FLAG', { isSaving: true });
    try {
      const { data } = await CrmTasksAPI.update(id, { task });
      if (dealId) {
        await dispatch('fetchDealTasks', dealId);
      } else if (listParams) {
        await dispatch('fetchTasks', listParams);
      }
      return data.payload;
    } catch (error) {
      throwErrorMessage(error);
      throw error;
    } finally {
      commit('SET_UI_FLAG', { isSaving: false });
    }
  },

  completeTask: async ({ dispatch }, { id, listParams, dealId }) => {
    await CrmTasksAPI.complete(id);
    if (dealId) {
      await dispatch('fetchDealTasks', dealId);
    } else if (listParams) {
      await dispatch('fetchTasks', listParams);
    }
  },

  cancelTask: async ({ dispatch }, { id, listParams, dealId }) => {
    await CrmTasksAPI.cancel(id);
    if (dealId) {
      await dispatch('fetchDealTasks', dealId);
    } else if (listParams) {
      await dispatch('fetchTasks', listParams);
    }
  },

  fetchActivities: async ({ commit }, dealId) => {
    const { data } = await CrmDealsAPI.getActivities(dealId);
    commit('SET_ACTIVITIES', data.payload || []);
  },

  createPipeline: async ({ dispatch, commit }, params) => {
    commit('SET_UI_FLAG', { isSaving: true });
    try {
      const { data } = await CrmPipelinesAPI.create({ pipeline: params });
      await dispatch('fetchPipelines');
      return data.payload;
    } catch (error) {
      throwErrorMessage(error);
      throw error;
    } finally {
      commit('SET_UI_FLAG', { isSaving: false });
    }
  },

  updatePipeline: async ({ dispatch, commit }, { id, params }) => {
    commit('SET_UI_FLAG', { isSaving: true });
    try {
      await CrmPipelinesAPI.update(id, { pipeline: params });
      await dispatch('fetchPipelines');
    } catch (error) {
      throwErrorMessage(error);
    } finally {
      commit('SET_UI_FLAG', { isSaving: false });
    }
  },

  deletePipeline: async ({ dispatch, commit }, id) => {
    commit('SET_UI_FLAG', { isSaving: true });
    try {
      await CrmPipelinesAPI.delete(id);
      await dispatch('fetchPipelines');
    } catch (error) {
      throwErrorMessage(error);
    } finally {
      commit('SET_UI_FLAG', { isSaving: false });
    }
  },

  createStage: async ({ dispatch, commit }, { pipelineId, params }) => {
    commit('SET_UI_FLAG', { isSaving: true });
    try {
      await CrmPipelinesAPI.createStage(pipelineId, { stage: params });
      await dispatch('fetchPipelines');
    } catch (error) {
      throwErrorMessage(error);
    } finally {
      commit('SET_UI_FLAG', { isSaving: false });
    }
  },

  updateStage: async ({ dispatch, commit }, { id, params }) => {
    commit('SET_UI_FLAG', { isSaving: true });
    try {
      await CrmStagesAPI.update(id, { stage: params });
      await dispatch('fetchPipelines');
    } catch (error) {
      throwErrorMessage(error);
    } finally {
      commit('SET_UI_FLAG', { isSaving: false });
    }
  },

  deleteStage: async ({ dispatch, commit }, id) => {
    commit('SET_UI_FLAG', { isSaving: true });
    try {
      await CrmStagesAPI.delete(id);
      await dispatch('fetchPipelines');
    } catch (error) {
      throwErrorMessage(error);
    } finally {
      commit('SET_UI_FLAG', { isSaving: false });
    }
  },
};

export const mutations = {
  SET_PIPELINES($state, pipelines) {
    $state.pipelines = pipelines;
  },
  SET_SELECTED_PIPELINE_ID($state, id) {
    $state.selectedPipelineId = id;
  },
  SET_DEALS($state, deals) {
    $state.deals = deals;
  },
  SET_TASKS($state, tasks) {
    $state.tasks = tasks;
  },
  SET_DEAL_TASKS($state, tasks) {
    $state.dealTasks = tasks;
  },
  SET_CURRENT_DEAL($state, deal) {
    $state.currentDeal = deal;
  },
  SET_DEAL_NOTES($state, notes) {
    $state.dealNotes = notes;
  },
  ADD_DEAL_NOTE($state, note) {
    $state.dealNotes = [note, ...$state.dealNotes];
  },
  REMOVE_DEAL_NOTE($state, noteId) {
    $state.dealNotes = $state.dealNotes.filter(note => note.id !== noteId);
  },
  SET_ACTIVITIES($state, activities) {
    $state.activities = activities;
  },
  SET_UI_FLAG($state, flags) {
    $state.uiFlags = { ...$state.uiFlags, ...flags };
  },
};

export default {
  namespaced: true,
  state,
  getters,
  actions,
  mutations,
};
