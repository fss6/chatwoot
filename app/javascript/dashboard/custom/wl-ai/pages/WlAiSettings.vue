<script setup>
import { ref, onMounted } from 'vue';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import wlAiCredential from 'dashboard/api/wlAi/credential';
import Input from 'dashboard/components-next/input/Input.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import Select from 'dashboard/components-next/select/Select.vue';
import TextArea from 'dashboard/components-next/textarea/TextArea.vue';

const { t } = useI18n();

const apiBase = ref('');
const apiToken = ref('');
const systemInstructions = ref('');
const selectedModel = ref('');
const modelOptions = ref([]);
const configured = ref(false);
const tokenLastFour = ref(null);
const isFetching = ref(true);
const isSaving = ref(false);
const isPinging = ref(false);
const saveError = ref('');

const load = async () => {
  isFetching.value = true;
  saveError.value = '';
  try {
    const { data } = await wlAiCredential.show();
    apiBase.value = data.api_base || '';
    systemInstructions.value = data.system_instructions || '';
    configured.value = data.configured;
    tokenLastFour.value = data.token_last_four;
    apiToken.value = '';
    modelOptions.value = (data.available_models || []).map(m => ({
      value: m.id,
      label: m.display_name,
    }));
    selectedModel.value =
      data.default_model || data.effective_default_model || '';
  } catch {
    useAlert(t('WL_AI.SETTINGS.FETCH_ERROR'));
  } finally {
    isFetching.value = false;
  }
};

const save = async () => {
  isSaving.value = true;
  saveError.value = '';
  try {
    const payload = {
      api_base: apiBase.value,
      default_model: selectedModel.value || null,
      system_instructions: systemInstructions.value,
    };
    if (apiToken.value) {
      payload.api_token = apiToken.value;
    }
    await wlAiCredential.update(payload);
    useAlert(t('WL_AI.SETTINGS.SAVED'));
    await load();
  } catch (error) {
    saveError.value =
      error.response?.data?.error ||
      error.response?.data?.message ||
      t('WL_AI.SETTINGS.SAVE_ERROR');
  } finally {
    isSaving.value = false;
  }
};

const ping = async () => {
  isPinging.value = true;
  try {
    await wlAiCredential.ping();
    useAlert(t('WL_AI.SETTINGS.PING_OK'));
  } catch (error) {
    const msg = error.response?.data?.error || t('WL_AI.SETTINGS.PING_ERROR');
    useAlert(msg);
  } finally {
    isPinging.value = false;
  }
};

onMounted(() => {
  load();
});
</script>

<template>
  <div
    class="flex flex-col w-full h-full min-h-0 gap-6 p-6 overflow-y-auto text-n-slate-12"
  >
    <header class="flex flex-col gap-1">
      <h1 class="text-xl font-semibold text-n-slate-12">
        {{ t('WL_AI.SETTINGS.TITLE') }}
      </h1>
      <p class="text-sm text-n-slate-11">
        {{ t('WL_AI.SETTINGS.DESCRIPTION') }}
      </p>
    </header>

    <woot-loading-state v-if="isFetching" />

    <form v-else class="flex flex-col max-w-xl gap-5" @submit.prevent="save">
      <Input
        v-model="apiBase"
        type="text"
        :label="t('WL_AI.SETTINGS.API_BASE_LABEL')"
        :placeholder="t('WL_AI.SETTINGS.API_BASE_PLACEHOLDER')"
      />

      <div class="flex flex-col gap-1.5">
        <span class="text-sm font-medium text-n-slate-11">
          {{ t('WL_AI.SETTINGS.MODEL_LABEL') }}
        </span>
        <Select
          v-model="selectedModel"
          :options="modelOptions"
          :placeholder="t('WL_AI.SETTINGS.MODEL_PLACEHOLDER')"
        />
      </div>

      <TextArea
        v-model="systemInstructions"
        :label="t('WL_AI.SETTINGS.SYSTEM_INSTRUCTIONS_LABEL')"
        :placeholder="t('WL_AI.SETTINGS.SYSTEM_INSTRUCTIONS_PLACEHOLDER')"
        :message="t('WL_AI.SETTINGS.SYSTEM_INSTRUCTIONS_HINT')"
        :max-length="100_000"
        :show-character-count="false"
        min-height="6rem"
        resize
      />

      <div class="flex flex-col gap-2">
        <Input
          v-model="apiToken"
          type="password"
          :label="t('WL_AI.SETTINGS.API_TOKEN_LABEL')"
          :placeholder="t('WL_AI.SETTINGS.API_TOKEN_PLACEHOLDER')"
          :message="
            configured && !apiToken
              ? t('WL_AI.SETTINGS.TOKEN_HINT', {
                  hint: tokenLastFour || '****',
                })
              : ''
          "
        />
      </div>

      <p v-if="saveError" class="text-sm text-n-ruby-11">
        {{ saveError }}
      </p>

      <div class="flex flex-wrap items-center gap-3">
        <Button
          type="submit"
          :label="t('WL_AI.SETTINGS.SAVE')"
          :is-loading="isSaving"
        />
        <Button
          type="button"
          variant="smooth"
          :label="t('WL_AI.SETTINGS.TEST_CONNECTION')"
          :is-loading="isPinging"
          :disabled="!configured && !apiToken"
          @click="ping"
        />
      </div>
    </form>
  </div>
</template>
