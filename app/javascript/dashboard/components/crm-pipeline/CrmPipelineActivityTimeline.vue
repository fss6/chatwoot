<script setup>
defineProps({
  activities: { type: Array, default: () => [] },
  showTitle: { type: Boolean, default: true },
});
</script>

<template>
  <div>
    <h4 v-if="showTitle" class="text-sm font-semibold text-n-slate-12 mb-3">
      {{ $t('CRM_PIPELINE.ACTIVITY.TITLE') }}
    </h4>
    <ul v-if="activities.length" class="space-y-4">
      <li
        v-for="activity in activities"
        :key="activity.id"
        class="flex gap-3 text-sm"
      >
        <span
          class="mt-2 size-2 shrink-0 rounded-full bg-n-slate-10"
          aria-hidden="true"
        />
        <div class="min-w-0">
          <p class="text-n-slate-12">
            <span class="font-medium">{{ activity.action }}</span>
            <span v-if="activity.actor" class="text-n-slate-11">
              {{ activity.actor.name }}
            </span>
          </p>
          <p class="text-xs text-n-slate-11 mt-0.5">
            {{ new Date(activity.created_at).toLocaleString() }}
          </p>
        </div>
      </li>
    </ul>
    <p v-else class="text-sm text-n-slate-11">
      {{ $t('CRM_PIPELINE.ACTIVITY.EMPTY') }}
    </p>
  </div>
</template>
