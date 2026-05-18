<script setup>
import { useRouter } from 'vue-router';
import { useAccount } from 'dashboard/composables/useAccount';
import { frontendURL, conversationUrl } from 'dashboard/helper/URLHelper';
import Button from 'dashboard/components-next/button/Button.vue';
import CrmPipelineDealPanelCard from './CrmPipelineDealPanelCard.vue';

const props = defineProps({
  deal: { type: Object, required: true },
});

const router = useRouter();
const { accountId } = useAccount();

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
  <aside v-if="deal.conversation" class="flex flex-col gap-5 min-w-0">
    <CrmPipelineDealPanelCard :title="$t('CRM_PIPELINE.SIDEBAR.TITLE')">
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
