<script setup>
defineProps({
  label: { type: String, required: true },
  alignTop: { type: Boolean, default: false },
});
</script>

<template>
  <div
    class="grid grid-cols-[10rem_minmax(0,1fr)] gap-x-6 gap-y-1 py-2.5 border-b border-n-weak last:border-b-0"
    :class="alignTop ? 'items-start' : 'items-center'"
  >
    <span class="text-xs font-medium text-n-slate-11 pt-0.5">
      {{ label }}
    </span>
    <div class="min-w-0 text-sm text-n-slate-12">
      <slot />
    </div>
  </div>
</template>
