<script setup>
import { computed } from 'vue';
import { useRouter } from 'vue-router';
import { useAccount } from 'dashboard/composables/useAccount';
import { frontendURL, conversationUrl } from 'dashboard/helper/URLHelper';
import Button from 'dashboard/components-next/button/Button.vue';
import CrmPipelineDealPanelCard from './CrmPipelineDealPanelCard.vue';
import {
  contactCompanyName,
  initialsFromName,
} from 'dashboard/composables/useCrmDealCardPresentation';

const props = defineProps({
  deal: { type: Object, required: true },
});

const router = useRouter();
const { accountId } = useAccount();

const contactInitials = computed(() =>
  initialsFromName(props.deal.contact?.name)
);

const companyName = computed(() => contactCompanyName(props.deal.contact));

const assigneeInitials = computed(() =>
  initialsFromName(props.deal.assigned_user?.name)
);

const openConversation = () => {
  const conversation = props.deal.conversation;
  if (!conversation) return;
  router.push(
    frontendURL(
      conversationUrl({
        accountId: accountId.value,
        activeInbox: conversation.inbox_id,
        id: conversation.display_id || conversation.id,
      })
    )
  );
};
</script>

<template>
  <aside class="flex flex-col gap-5 min-w-0">
    <CrmPipelineDealPanelCard
      v-if="deal.contact"
      :title="$t('CRM_PIPELINE.DEAL.CONTACT')"
    >
      <div class="flex items-center gap-3">
        <div
          class="flex size-10 shrink-0 items-center justify-center rounded-full bg-n-slate-12 text-sm font-bold text-white"
        >
          {{ contactInitials }}
        </div>
        <div class="min-w-0">
          <p class="truncate text-sm font-semibold text-n-slate-12">
            {{ deal.contact.name }}
          </p>
          <p v-if="companyName" class="truncate text-xs text-n-slate-11 mt-0.5">
            {{ companyName }}
          </p>
        </div>
      </div>

      <div class="mt-4 space-y-3 text-sm text-n-slate-11">
        <p v-if="deal.contact.email" class="flex items-center gap-2 min-w-0">
          <span class="i-lucide-mail size-4 shrink-0 text-n-slate-10" />
          <span class="truncate">{{ deal.contact.email }}</span>
        </p>
        <p v-if="deal.contact.phone_number" class="flex items-center gap-2">
          <span class="i-lucide-phone size-4 shrink-0 text-n-slate-10" />
          <span>{{ deal.contact.phone_number }}</span>
        </p>
      </div>
    </CrmPipelineDealPanelCard>

    <CrmPipelineDealPanelCard :title="$t('CRM_PIPELINE.DEAL.ASSIGNEE')">
      <div class="flex items-center gap-3">
        <div
          v-if="assigneeInitials"
          class="flex size-9 shrink-0 items-center justify-center rounded-full bg-n-slate-12 text-xs font-bold text-white"
        >
          {{ assigneeInitials }}
        </div>
        <div
          v-else
          class="flex size-9 shrink-0 items-center justify-center rounded-full bg-n-alpha-2 text-n-slate-10"
        >
          <span class="i-lucide-user-round size-4" aria-hidden="true" />
        </div>
        <div class="min-w-0">
          <p class="text-sm font-semibold text-n-slate-12 truncate">
            {{ deal.assigned_user?.name || $t('CRM_PIPELINE.DEAL.UNASSIGNED') }}
          </p>
          <p class="text-xs text-n-slate-11 mt-0.5">
            {{ $t('CRM_PIPELINE.DEAL.OWNER_ROLE') }}
          </p>
        </div>
      </div>
    </CrmPipelineDealPanelCard>

    <CrmPipelineDealPanelCard
      v-if="deal.conversation"
      :title="$t('CRM_PIPELINE.SIDEBAR.TITLE')"
    >
      <p class="text-sm leading-6 text-n-slate-11">
        {{ $t('CRM_PIPELINE.DEAL.CONVERSATION_HINT') }}
      </p>
      <Button
        sm
        variant="outline"
        color="slate"
        icon="i-lucide-message-square"
        class="w-full mt-4"
        :label="$t('CRM_PIPELINE.DEAL.OPEN_CONVERSATION')"
        @click="openConversation"
      />
    </CrmPipelineDealPanelCard>
  </aside>
</template>
