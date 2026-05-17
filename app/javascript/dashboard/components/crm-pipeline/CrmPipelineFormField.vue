<script setup>
defineProps({
  label: { type: String, required: true },
  hasError: { type: Boolean, default: false },
});
</script>

<template>
  <div class="w-full">
    <label :class="{ error: hasError }">
      {{ label }}
      <slot />
    </label>
  </div>
</template>
