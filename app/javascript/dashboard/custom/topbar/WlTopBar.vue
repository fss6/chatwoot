<script setup>
/**
 * Topbar customizada do fork (white-label).
 *
 * Migra search + "Nova conversa" + account switcher do topo da sidebar
 * para uma barra horizontal acima do <main>. A sidebar passa a ser nav
 * rail pura (logo + menu + profile).
 *
 * Ativada por `sidebarConfig.useTopBar = true`. Quando desligada, o
 * Dashboard.vue nao renderiza esse componente e a sidebar volta ao layout
 * upstream (atraves do v-if espelhado em Sidebar.vue).
 *
 * Reusa os componentes do upstream (SidebarAccountSwitcher, ComposeConversation,
 * Button) para evitar duplicar logica de account switching, atalhos e modais.
 */
import { useI18n } from 'vue-i18n';
import { useKbd } from 'dashboard/composables/utils/useKbd';
import SidebarAccountSwitcher from 'dashboard/components-next/sidebar/SidebarAccountSwitcher.vue';
import ComposeConversation from 'dashboard/components-next/NewConversation/ComposeConversation.vue';
import Button from 'dashboard/components-next/button/Button.vue';

defineEmits(['showCreateAccountModal']);

const { t } = useI18n();
const searchShortcut = useKbd(['$mod', 'k']);
</script>

<template>
  <header
    class="wl-topbar--contrast flex items-center gap-2 px-4 h-12 flex-shrink-0"
  >
    <RouterLink
      :to="{ name: 'search' }"
      class="flex gap-2 items-center px-2.5 py-1 h-8 w-full max-w-md rounded-lg transition-all duration-100 ease-out"
    >
      <span class="flex-shrink-0 i-lucide-search size-4" />
      <span class="flex-grow text-start text-sm">
        {{ t('COMBOBOX.SEARCH_PLACEHOLDER') }}
      </span>
      <span
        class="hidden sm:inline-block tracking-wide pointer-events-none select-none text-xs"
      >
        {{ searchShortcut }}
      </span>
    </RouterLink>

    <ComposeConversation align="start">
      <template #trigger="{ isOpen }">
        <Button
          icon="i-lucide-pen-line"
          color="slate"
          size="sm"
          class="!h-8 flex-shrink-0"
          :class="{ 'is-open': isOpen }"
        />
      </template>
    </ComposeConversation>

    <div class="flex-grow" />

    <div class="wl-account-switcher flex-shrink-0 min-w-0 max-w-[14rem]">
      <SidebarAccountSwitcher
        @show-create-account-modal="$emit('showCreateAccountModal')"
      />
    </div>
  </header>
</template>
