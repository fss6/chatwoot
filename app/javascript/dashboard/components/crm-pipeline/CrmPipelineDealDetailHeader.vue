<script setup>
import { useRouter } from 'vue-router';
import { useAccount } from 'dashboard/composables/useAccount';
import { frontendURL, conversationUrl } from 'dashboard/helper/URLHelper';
import Button from 'dashboard/components-next/button/Button.vue';

const props = defineProps({
  deal: { type: Object, required: true },
  pipelineDealsRoute: { type: Object, required: true },
});

const emit = defineEmits(['win', 'lose']);

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
  <header class="flex flex-col gap-3 min-w-0">
    <nav
      class="flex flex-wrap items-center gap-1.5 text-xs text-n-slate-11"
      :aria-label="$t('CRM_PIPELINE.DEAL.BREADCRUMB_CRM')"
    >
      <router-link
        :to="pipelineDealsRoute"
        class="inline-flex items-center text-n-slate-11 transition-colors hover:text-n-slate-12"
        :aria-label="$t('CRM_PIPELINE.DEAL.BACK_TO_PIPELINE')"
      >
        <span class="i-lucide-arrow-left size-4 shrink-0" aria-hidden="true" />
      </router-link>
      <router-link
        :to="pipelineDealsRoute"
        class="font-medium transition-colors hover:text-n-slate-12"
      >
        {{ $t('CRM_PIPELINE.DEAL.BREADCRUMB_CRM') }}
      </router-link>
      <span class="i-lucide-chevron-right size-3 shrink-0" aria-hidden="true" />
      <span class="font-medium text-n-slate-12">
        {{ deal.pipeline?.name }}
      </span>
      <span class="i-lucide-chevron-right size-3 shrink-0" aria-hidden="true" />
      <span class="font-medium text-n-slate-12">
        {{ deal.stage?.name }}
      </span>
    </nav>

    <h1 class="text-heading-1 text-n-slate-12 break-words">
      {{ deal.title }}
    </h1>

    <div class="flex flex-wrap items-center gap-2">
      <Button
        v-if="deal.conversation"
        sm
        faded
        slate
        icon="i-lucide-message-square"
        :label="$t('CRM_PIPELINE.DEAL.OPEN_CONVERSATION')"
        @click="openConversation"
      />
      <Button
        sm
        faded
        teal
        icon="i-lucide-check"
        :label="$t('CRM_PIPELINE.DEAL.WIN')"
        @click="emit('win')"
      />
      <Button
        sm
        faded
        ruby
        icon="i-lucide-x"
        :label="$t('CRM_PIPELINE.DEAL.LOSE')"
        @click="emit('lose')"
      />
    </div>
  </header>
</template>
