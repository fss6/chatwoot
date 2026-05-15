<script setup>
import { ref, onMounted } from 'vue';
import { useRoute, useRouter } from 'vue-router';
import wlBotFlows from 'dashboard/api/wlBotFlows/flows';
import Button from 'dashboard/components-next/button/Button.vue';

const route = useRoute();
const router = useRouter();
const logs = ref([]);

const loadLogs = async () => {
  const { data } = await wlBotFlows.executionLogs(route.params.flowId);
  logs.value = data.execution_logs || [];
};

const goBack = () => {
  router.push({
    name: 'wl_bot_flow_editor',
    params: {
      accountId: route.params.accountId,
      flowId: route.params.flowId,
    },
  });
};

onMounted(loadLogs);
</script>

<template>
  <div class="flex flex-col w-full h-full p-6 gap-4 overflow-auto">
    <div class="flex items-center gap-3">
      <Button
        ghost
        xs
        :label="$t('WL_BOT_FLOWS.ACTIONS.BACK')"
        @click="goBack"
      />
      <h1 class="text-xl font-semibold text-n-slate-12">
        {{ $t('WL_BOT_FLOWS.LOGS.TITLE') }}
      </h1>
    </div>
    <p v-if="!logs.length" class="text-n-slate-11">
      {{ $t('WL_BOT_FLOWS.LOGS.EMPTY') }}
    </p>
    <table v-else class="w-full text-sm">
      <thead>
        <tr class="text-left border-b border-n-weak text-n-slate-11">
          <th class="py-2">{{ $t('WL_BOT_FLOWS.LOGS.CONVERSATION') }}</th>
          <th class="py-2">{{ $t('WL_BOT_FLOWS.LOGS.GROUP') }}</th>
          <th class="py-2">{{ $t('WL_BOT_FLOWS.LOGS.ACTION') }}</th>
          <th class="py-2">{{ $t('WL_BOT_FLOWS.LOGS.STATUS') }}</th>
          <th class="py-2">{{ $t('WL_BOT_FLOWS.LOGS.ERROR') }}</th>
        </tr>
      </thead>
      <tbody>
        <tr v-for="log in logs" :key="log.id" class="border-b border-n-weak">
          <td class="py-2">{{ log.conversation_id }}</td>
          <td class="py-2">{{ log.group_id }}</td>
          <td class="py-2">{{ log.action_type }}</td>
          <td class="py-2">{{ log.status }}</td>
          <td class="py-2 text-n-slate-11">{{ log.error_message || '—' }}</td>
        </tr>
      </tbody>
    </table>
  </div>
</template>
