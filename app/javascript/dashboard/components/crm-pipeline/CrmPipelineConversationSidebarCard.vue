<script setup>
import { ref, computed, onMounted, watch } from 'vue';
import { useStore, useMapGetter } from 'dashboard/composables/store';
import { useAccount } from 'dashboard/composables/useAccount';
import { FEATURE_FLAGS } from 'dashboard/featureFlags';
import { frontendURL } from 'dashboard/helper/URLHelper';
import CrmPipelineDealModal from './CrmPipelineDealModal.vue';
import CrmPipelineTaskModal from './CrmPipelineTaskModal.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import CrmDealsAPI from 'dashboard/api/crm/deals';

const props = defineProps({
  conversationId: { type: [Number, String], required: true },
  contactId: { type: [Number, String], required: true },
});

const store = useStore();
const { accountId, isCloudFeatureEnabled } = useAccount();

const deals = ref([]);
const showCreateModal = ref(false);
const selectedDeal = ref(null);
const showDealModal = ref(false);
const showTaskModal = ref(false);

const isEnabled = computed(() =>
  isCloudFeatureEnabled(FEATURE_FLAGS.CRM_PIPELINE)
);

const contactGetter = useMapGetter('contacts/getContact');
const contact = computed(() => contactGetter.value(Number(props.contactId)));

const primaryDeal = computed(() => deals.value[0]);
const stages = computed(() => store.getters['crmPipeline/getStages']);
const agents = computed(() => store.getters['agents/getAgents'] || []);

const fetchDeals = async () => {
  if (!isEnabled.value) return;
  const { data } = await CrmDealsAPI.get({
    contact_id: props.contactId,
    conversation_id: props.conversationId,
  });
  deals.value = data.payload || [];
};

const openCreate = async () => {
  await store.dispatch('crmPipeline/fetchPipelines');
  showCreateModal.value = true;
};

const crmDealsUrl = computed(() =>
  frontendURL(`accounts/${accountId.value}/crm/deals`)
);

watch(
  () => [props.conversationId, props.contactId],
  () => fetchDeals(),
  { immediate: true }
);

onMounted(() => {
  store.dispatch('agents/get');
  if (props.contactId) {
    store.dispatch('contacts/show', { id: props.contactId });
  }
});
</script>

<template>
  <div v-if="isEnabled" class="space-y-2">
    <template v-if="primaryDeal">
      <p class="text-sm font-medium text-n-slate-12">{{ primaryDeal.title }}</p>
      <p class="text-xs text-n-slate-11">
        {{ $t('CRM_PIPELINE.SIDEBAR.STAGE') }}: {{ primaryDeal.stage?.name }}
      </p>
      <p v-if="primaryDeal.amount" class="text-xs text-n-slate-11">
        {{ primaryDeal.amount }} {{ primaryDeal.currency }}
      </p>
      <div class="flex flex-wrap gap-2 pt-1">
        <router-link
          :to="crmDealsUrl"
          class="text-xs text-n-brand hover:underline"
        >
          {{ $t('CRM_PIPELINE.SIDEBAR.VIEW_CRM') }}
        </router-link>
        <button
          type="button"
          class="text-xs text-n-brand hover:underline"
          @click="
            selectedDeal = primaryDeal;
            showDealModal = true;
          "
        >
          {{ $t('CRM_PIPELINE.SIDEBAR.VIEW_DEAL') }}
        </button>
      </div>
      <Button
        sm
        faded
        class="mt-1"
        :label="$t('CRM_PIPELINE.TASKS.ADD_TASK')"
        @click="showTaskModal = true"
      />
    </template>
    <template v-else>
      <p class="text-xs text-n-slate-11">
        {{ $t('CRM_PIPELINE.SIDEBAR.NO_DEAL') }}
      </p>
      <Button
        sm
        faded
        :label="$t('CRM_PIPELINE.SIDEBAR.CREATE_DEAL')"
        @click="openCreate"
      />
    </template>

    <CrmPipelineDealModal
      :show="showCreateModal"
      is-create
      :stages="stages"
      :agents="agents"
      :locked-contact="contact"
      :initial-values="{
        contact_id: Number(contactId),
        conversation_id: Number(conversationId),
        pipeline_id: store.getters['crmPipeline/getSelectedPipeline']?.id,
      }"
      @close="showCreateModal = false"
      @saved="fetchDeals"
    />

    <CrmPipelineDealModal
      :show="showDealModal"
      :deal="selectedDeal"
      :stages="stages"
      :agents="agents"
      @close="showDealModal = false"
      @saved="fetchDeals"
    />

    <CrmPipelineTaskModal
      :show="showTaskModal"
      :locked-deal="primaryDeal"
      :locked-conversation-id="Number(conversationId)"
      :agents="agents"
      @close="showTaskModal = false"
    />
  </div>
</template>
