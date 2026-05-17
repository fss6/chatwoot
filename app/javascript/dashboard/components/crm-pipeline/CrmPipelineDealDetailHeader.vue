<script setup>
import Button from 'dashboard/components-next/button/Button.vue';

defineProps({
  deal: { type: Object, required: true },
  pageHeader: { type: Boolean, default: false },
});

const emit = defineEmits(['win', 'lose', 'edit']);
</script>

<template>
  <header
    :class="
      pageHeader
        ? 'flex flex-col gap-3 min-w-0'
        : 'mb-5 pb-5 border-b border-n-weak'
    "
  >
    <div v-if="pageHeader" class="flex flex-wrap items-center gap-2">
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

    <p class="flex items-center gap-1.5 text-xs text-n-slate-11">
      <span>{{ $t('CRM_PIPELINE.DEAL.BREADCRUMB_CRM') }}</span>
      <span class="i-lucide-chevron-right size-3 shrink-0" aria-hidden="true" />
      <span class="text-n-slate-12">{{ deal.stage?.name }}</span>
    </p>

    <template v-if="!pageHeader">
      <h2 class="text-xl font-bold leading-7 text-n-slate-12 break-words">
        {{ deal.title }}
      </h2>
      <div class="flex flex-wrap items-center gap-2">
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
    </template>
  </header>
</template>
