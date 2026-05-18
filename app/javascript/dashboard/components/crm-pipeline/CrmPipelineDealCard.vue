<script setup>
import { toRef } from 'vue';
import { useCrmDealCardPresentation } from 'dashboard/composables/useCrmDealCardPresentation';

const props = defineProps({
  deal: { type: Object, required: true },
  draggable: { type: Boolean, default: true },
});

const emit = defineEmits(['click']);

const {
  formattedAmount,
  showValueRow,
  temperature,
  footerStatusText,
  footerStatusClasses,
  contactSubtitle,
  assigneeName,
  assigneeInitials,
} = useCrmDealCardPresentation(toRef(props, 'deal'));

const onActivate = () => emit('click', props.deal);
</script>

<template>
  <button
    type="button"
    class="group relative w-full text-left rounded-2xl border border-n-weak bg-n-solid-1 p-3 shadow-sm transition-all duration-150"
    :class="
      draggable
        ? 'cursor-grab hover:-translate-y-0.5 hover:border-n-strong hover:shadow-md active:cursor-grabbing active:scale-[0.99]'
        : 'crm-deal-card--no-drag cursor-pointer'
    "
    @click="onActivate"
  >
    <span
      v-if="draggable"
      class="absolute top-2 ltr:right-2 rtl:left-2 i-lucide-grip-vertical size-4 text-n-slate-10 opacity-0 transition-opacity group-hover:opacity-40 pointer-events-none"
      aria-hidden="true"
    />

    <div class="space-y-1 ltr:pr-5 rtl:pl-5">
      <h3 class="line-clamp-2 text-sm font-semibold leading-5 text-n-slate-12">
        {{ deal.title }}
      </h3>
      <p v-if="contactSubtitle" class="truncate text-xs text-n-slate-11">
        {{ contactSubtitle }}
      </p>
    </div>

    <div
      v-if="showValueRow"
      class="mt-3 flex items-center justify-between gap-2"
    >
      <span
        v-if="formattedAmount"
        class="truncate text-sm font-semibold tabular-nums text-n-slate-12"
      >
        {{ formattedAmount }}
      </span>
      <span v-else />
      <span
        v-if="temperature"
        class="inline-flex shrink-0 items-center gap-1 rounded-full px-2 py-0.5 text-[11px] font-medium"
        :class="temperature.badgeClass"
        :title="temperature.label"
        :aria-label="temperature.label"
      >
        <span class="size-3" :class="temperature.icon" aria-hidden="true" />
        {{ temperature.label }}
      </span>
    </div>

    <div class="mt-3 border-t border-n-weak pt-2">
      <div class="flex items-center justify-between gap-2">
        <p class="min-w-0 flex-1 truncate text-xs" :class="footerStatusClasses">
          {{ footerStatusText }}
        </p>
        <div
          v-if="assigneeInitials"
          class="flex size-6 shrink-0 items-center justify-center rounded-full bg-n-slate-12 text-[10px] font-bold text-white"
          :title="assigneeName"
        >
          {{ assigneeInitials }}
        </div>
        <div
          v-else
          class="flex size-6 shrink-0 items-center justify-center rounded-full bg-n-alpha-2 text-n-slate-10"
          :title="assigneeName"
        >
          <span class="i-lucide-user-round size-3.5" aria-hidden="true" />
        </div>
      </div>
    </div>
  </button>
</template>
