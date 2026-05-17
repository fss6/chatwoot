<script setup>
defineProps({
  title: { type: String, default: '' },
});
</script>

<template>
  <section
    class="rounded-2xl border border-n-weak bg-n-solid-1 shadow-sm overflow-hidden"
  >
    <header
      v-if="title || $slots.header"
      class="flex items-center justify-between gap-3 px-5 py-4"
    >
      <h3 v-if="title" class="text-sm font-bold text-n-slate-12">
        {{ title }}
      </h3>
      <div
        v-if="$slots.header"
        class="flex min-w-0 flex-1 items-center justify-between gap-3"
      >
        <slot name="header" />
      </div>
    </header>
    <div
      class="px-5 pb-5"
      :class="{
        'pt-0': title || $slots.header,
        'py-5': !title && !$slots.header,
      }"
    >
      <slot />
    </div>
  </section>
</template>
