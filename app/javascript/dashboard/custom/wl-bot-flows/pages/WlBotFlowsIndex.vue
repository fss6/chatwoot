<script setup>
import { ref, onMounted, computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { useRouter } from 'vue-router';
import { useAlert } from 'dashboard/composables';
import wlBotFlows from 'dashboard/api/wlBotFlows/flows';
import Button from 'dashboard/components-next/button/Button.vue';

const { t } = useI18n();
const router = useRouter();
const flows = ref([]);
const isLoading = ref(true);

const accountId = computed(() => router.currentRoute.value.params.accountId);

const loadFlows = async () => {
  isLoading.value = true;
  try {
    const { data } = await wlBotFlows.index();
    flows.value = data;
  } catch {
    useAlert(t('WL_BOT_FLOWS.MESSAGES.ERROR'));
  } finally {
    isLoading.value = false;
  }
};

const createFlow = async () => {
  try {
    const { data } = await wlBotFlows.create({
      name: t('WL_BOT_FLOWS.NEW_FLOW'),
    });
    router.push({
      name: 'wl_bot_flow_editor',
      params: { accountId: accountId.value, flowId: data.id },
    });
  } catch {
    useAlert(t('WL_BOT_FLOWS.MESSAGES.ERROR'));
  }
};

const openEditor = id => {
  router.push({
    name: 'wl_bot_flow_editor',
    params: { accountId: accountId.value, flowId: id },
  });
};

const publishFlow = async id => {
  try {
    await wlBotFlows.publish(id);
    useAlert(t('WL_BOT_FLOWS.MESSAGES.PUBLISHED'));
    await loadFlows();
  } catch (e) {
    useAlert(e.response?.data?.error || t('WL_BOT_FLOWS.MESSAGES.ERROR'));
  }
};

const pauseFlow = async id => {
  try {
    await wlBotFlows.pause(id);
    useAlert(t('WL_BOT_FLOWS.MESSAGES.PAUSED'));
    await loadFlows();
  } catch {
    useAlert(t('WL_BOT_FLOWS.MESSAGES.ERROR'));
  }
};

const duplicateFlow = async id => {
  try {
    await wlBotFlows.duplicate(id);
    await loadFlows();
  } catch {
    useAlert(t('WL_BOT_FLOWS.MESSAGES.ERROR'));
  }
};

const deleteFlow = async id => {
  try {
    await wlBotFlows.destroy(id);
    useAlert(t('WL_BOT_FLOWS.MESSAGES.DELETED'));
    await loadFlows();
  } catch {
    useAlert(t('WL_BOT_FLOWS.MESSAGES.ERROR'));
  }
};

onMounted(loadFlows);
</script>

<template>
  <div class="flex flex-col w-full h-full p-6 gap-4 overflow-auto">
    <div class="flex items-center justify-between">
      <h1 class="text-xl font-semibold text-n-slate-12">
        {{ $t('WL_BOT_FLOWS.TITLE') }}
      </h1>
      <Button :label="$t('WL_BOT_FLOWS.NEW_FLOW')" @click="createFlow" />
    </div>

    <div v-if="isLoading" class="text-n-slate-11">...</div>
    <p v-else-if="!flows.length" class="text-n-slate-11">
      {{ $t('WL_BOT_FLOWS.EMPTY') }}
    </p>

    <table v-else class="w-full text-sm border-collapse">
      <thead>
        <tr class="text-left border-b border-n-weak text-n-slate-11">
          <th class="py-2">{{ $t('WL_BOT_FLOWS.TABLE.NAME') }}</th>
          <th class="py-2">{{ $t('WL_BOT_FLOWS.TABLE.INBOX') }}</th>
          <th class="py-2">{{ $t('WL_BOT_FLOWS.TABLE.STATUS') }}</th>
          <th class="py-2">{{ $t('WL_BOT_FLOWS.TABLE.UPDATED') }}</th>
          <th class="py-2">{{ $t('WL_BOT_FLOWS.TABLE.ACTIONS') }}</th>
        </tr>
      </thead>
      <tbody>
        <tr
          v-for="flow in flows"
          :key="flow.id"
          class="border-b border-n-weak hover:bg-n-alpha-1"
        >
          <td class="py-3 font-medium text-n-slate-12">{{ flow.name }}</td>
          <td class="py-3 text-n-slate-11">{{ flow.inbox_name || '—' }}</td>
          <td class="py-3 capitalize">{{ flow.status }}</td>
          <td class="py-3 text-n-slate-11">
            {{ new Date(flow.updated_at).toLocaleString() }}
          </td>
          <td class="py-3 flex flex-wrap gap-2">
            <Button
              ghost
              xs
              :label="$t('WL_BOT_FLOWS.ACTIONS.EDIT')"
              @click="openEditor(flow.id)"
            />
            <Button
              ghost
              xs
              :label="$t('WL_BOT_FLOWS.ACTIONS.PUBLISH')"
              @click="publishFlow(flow.id)"
            />
            <Button
              ghost
              xs
              :label="$t('WL_BOT_FLOWS.ACTIONS.PAUSE')"
              @click="pauseFlow(flow.id)"
            />
            <Button
              ghost
              xs
              :label="$t('WL_BOT_FLOWS.ACTIONS.DUPLICATE')"
              @click="duplicateFlow(flow.id)"
            />
            <Button
              ghost
              xs
              :label="$t('WL_BOT_FLOWS.ACTIONS.DELETE')"
              @click="deleteFlow(flow.id)"
            />
          </td>
        </tr>
      </tbody>
    </table>
  </div>
</template>
