<script setup>
import { ref, computed, onMounted, watch } from 'vue';
import { useStore, useMapGetter } from 'dashboard/composables/store';
import { useAccount } from 'dashboard/composables/useAccount';
import { FEATURE_FLAGS } from 'dashboard/featureFlags';
import { frontendURL } from 'dashboard/helper/URLHelper';
import { useRouter } from 'vue-router';
import CrmPipelineDealModal from './CrmPipelineDealModal.vue';
import CrmPipelineTaskModal from './CrmPipelineTaskModal.vue';
import NextButton from 'dashboard/components-next/button/Button.vue';
import CrmDealsAPI from 'dashboard/api/crm/deals';

const props = defineProps({
  conversationId: { type: [Number, String], required: true },
  contactId: { type: [Number, String], required: true },
});

const store = useStore();
const router = useRouter();
const { accountId, accountScopedRoute, isCloudFeatureEnabled } = useAccount();

const deals = ref([]);
const showCreateModal = ref(false);
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

const onDealCreated = deal => {
  showCreateModal.value = false;
  fetchDeals();
  if (deal?.id) {
    router.push(
      accountScopedRoute('crm_pipeline_deal_show', { dealId: deal.id })
    );
  }
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
  <div v-if="isEnabled" class="p-3 flex flex-col gap-3">
    <template v-if="primaryDeal">
      <div class="flex flex-col gap-1 min-w-0">
        <p class="text-sm font-medium text-n-slate-12 truncate">
          {{ primaryDeal.title }}
        </p>
        <p class="text-xs text-n-slate-11">
          {{ $t('CRM_PIPELINE.SIDEBAR.STAGE') }}: {{ primaryDeal.stage?.name }}
        </p>
        <p v-if="primaryDeal.amount" class="text-xs text-n-slate-11">
          {{ primaryDeal.amount }} {{ primaryDeal.currency }}
        </p>
      </div>
      <div class="flex flex-wrap items-center gap-x-3 gap-y-1">
        <router-link
          :to="crmDealsUrl"
          class="inline-flex items-center text-xs text-n-brand hover:underline"
        >
          {{ $t('CRM_PIPELINE.SIDEBAR.VIEW_CRM') }}
        </router-link>
        <router-link
          :to="
            accountScopedRoute('crm_pipeline_deal_show', {
              dealId: primaryDeal.id,
            })
          "
          class="inline-flex items-center text-xs text-n-brand hover:underline"
        >
          {{ $t('CRM_PIPELINE.SIDEBAR.VIEW_DEAL') }}
        </router-link>
      </div>
      <NextButton
        faded
        xs
        icon="i-lucide-plus"
        :label="$t('CRM_PIPELINE.TASKS.ADD_TASK')"
        @click="showTaskModal = true"
      />
    </template>
    <template v-else>
      <div class="flex flex-col items-center gap-3 text-center">
        <p class="text-sm text-n-slate-11">
          {{ $t('CRM_PIPELINE.SIDEBAR.NO_DEAL') }}
        </p>
        <NextButton
          faded
          xs
          icon="i-lucide-plus"
          :label="$t('CRM_PIPELINE.SIDEBAR.CREATE_DEAL')"
          @click="openCreate"
        />
      </div>
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
      @saved="onDealCreated"
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
