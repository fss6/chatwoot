<script setup>
import { computed } from 'vue';
import Button from 'dashboard/components-next/button/Button.vue';
import { contactCardSubtitle } from 'dashboard/composables/useCrmDealCardPresentation';

const props = defineProps({
  deal: { type: Object, required: true },
});

const emit = defineEmits(['win', 'lose', 'edit']);

const contactSubtitle = computed(() => contactCardSubtitle(props.deal.contact));
</script>

<template>
  <header class="mb-5 pb-5 border-b border-n-weak">
    <p class="flex items-center gap-1.5 text-xs text-n-slate-11 mb-2">
      <span>{{ $t('CRM_PIPELINE.DEAL.BREADCRUMB_CRM') }}</span>
      <span class="i-lucide-chevron-right size-3 shrink-0" aria-hidden="true" />
      <span class="text-n-slate-12">{{ deal.stage?.name }}</span>
    </p>
    <h2 class="text-xl font-bold leading-7 text-n-slate-12 break-words">
      {{ deal.title }}
    </h2>
    <p v-if="contactSubtitle" class="text-sm text-n-slate-11 mt-1">
      {{ contactSubtitle }}
    </p>
    <div class="flex flex-wrap items-center gap-2 mt-4">
      <Button
        sm
        faded
        teal
        icon="i-lucide-check-circle-2"
        :label="$t('CRM_PIPELINE.DEAL.WIN')"
        @click="emit('win')"
      />
      <Button
        sm
        faded
        ruby
        icon="i-lucide-x-circle"
        :label="$t('CRM_PIPELINE.DEAL.LOSE')"
        @click="emit('lose')"
      />
      <Button
        sm
        variant="outline"
        color="slate"
        icon="i-lucide-pencil"
        :label="$t('CRM_PIPELINE.DEAL.EDIT')"
        @click="emit('edit')"
      />
    </div>
  </header>
</template>
