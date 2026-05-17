<script setup>
defineProps({
  title: { type: String, required: true },
  description: { type: String, default: '' },
  fullWidth: { type: Boolean, default: false },
});
</script>

<template>
  <section class="flex w-full h-full bg-n-surface-1">
    <div class="flex flex-col w-full h-full min-h-0">
      <header
        class="sticky top-0 z-10 shrink-0 px-6 border-b border-n-weak bg-n-surface-1"
      >
        <div
          class="flex flex-col gap-3 w-full py-6 mx-auto"
          :class="fullWidth ? 'max-w-full' : 'max-w-7xl'"
        >
          <slot v-if="$slots.header" name="header" />
          <template v-else>
            <div
              class="flex flex-col gap-3 sm:flex-row sm:items-start sm:justify-between"
            >
              <div class="min-w-0">
                <h1 class="text-heading-1 text-n-slate-12">
                  {{ title }}
                </h1>
                <p
                  v-if="description || $slots.description"
                  class="text-body-main text-n-slate-11 mt-1 max-w-3xl"
                >
                  <slot name="description">{{ description }}</slot>
                </p>
              </div>
              <div
                v-if="$slots.actions"
                class="flex items-center gap-2 flex-shrink-0"
              >
                <slot name="actions" />
              </div>
            </div>
            <slot name="toolbar" />
          </template>
        </div>
      </header>

      <main class="flex-1 min-h-0 overflow-hidden px-6">
        <div
          class="w-full h-full mx-auto py-4"
          :class="fullWidth ? 'max-w-full' : 'max-w-7xl'"
        >
          <slot />
        </div>
      </main>
    </div>
  </section>
</template>
