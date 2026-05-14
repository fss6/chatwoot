<script setup>
import Button from 'dashboard/components-next/button/Button.vue';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';

defineProps({
  headerTitle: {
    type: String,
    default: '',
  },
  headerSubtitle: {
    type: String,
    default: '',
  },
  buttonLabel: {
    type: String,
    default: '',
  },
  isFetching: {
    type: Boolean,
    default: false,
  },
  isEmpty: {
    type: Boolean,
    default: false,
  },
  showKnowMore: {
    type: Boolean,
    default: false,
  },
});

defineEmits(['primaryClick']);
</script>

<template>
  <section class="flex flex-col w-full h-full overflow-hidden bg-n-surface-1">
    <header class="sticky top-0 z-10 px-6">
      <div class="w-full max-w-5xl mx-auto">
        <div
          class="flex items-start lg:items-center justify-between w-full py-6 lg:py-0 lg:h-20 gap-4 lg:gap-2 flex-col lg:flex-row"
        >
          <div class="flex gap-3 items-start min-w-0 flex-1 lg:items-center">
            <div class="flex flex-col min-w-0 gap-0.5">
              <span
                v-if="headerTitle"
                class="text-xl font-medium text-n-slate-12 truncate"
              >
                {{ headerTitle }}
              </span>
              <p
                v-if="headerSubtitle"
                class="text-sm text-n-slate-11 line-clamp-2 max-w-2xl"
              >
                {{ headerSubtitle }}
              </p>
            </div>
            <div
              v-if="!isEmpty && showKnowMore"
              class="hidden sm:flex items-center gap-2 shrink-0"
            >
              <div class="w-0.5 h-4 rounded-2xl bg-n-weak" />
              <slot name="knowMore" />
            </div>
          </div>
          <div class="flex gap-2 shrink-0">
            <slot name="search" />
            <Button
              v-if="buttonLabel"
              :label="buttonLabel"
              icon="i-lucide-plus"
              size="sm"
              @click="$emit('primaryClick')"
            />
          </div>
        </div>
        <slot name="subHeader" />
      </div>
    </header>
    <main class="flex-1 px-6 overflow-y-auto">
      <div class="w-full max-w-5xl h-full mx-auto py-4">
        <div
          v-if="isFetching"
          class="flex items-center justify-center py-10 text-n-slate-11"
        >
          <Spinner />
        </div>
        <div v-else-if="isEmpty">
          <slot name="emptyState" />
        </div>
        <slot v-else name="body" />
        <slot />
      </div>
    </main>
  </section>
</template>
