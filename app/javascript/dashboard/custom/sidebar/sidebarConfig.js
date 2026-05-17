/**
 * Sidebar fork customization.
 *
 * Esta é a configuração de produto deste fork (white-label). Ela controla
 * quais grupos de primeiro nível aparecem na sidebar do dashboard, em que
 * ordem, como são agrupados em seções e qual tema visual usar — sem precisar
 * editar `Sidebar.vue` do upstream.
 *
 * Os `name` aqui precisam bater EXATAMENTE com o campo `name` definido em
 * `app/javascript/dashboard/components-next/sidebar/Sidebar.vue` (computed
 * `menuItems`). Valores válidos hoje:
 *
 *   'Inbox', 'Conversation', 'Captain', 'WlAi', 'WlAiAssistants', 'WlAiPlayground', 'WlAiSettings', 'WlAiFaqs', 'Contacts', 'Companies',
 *   'Reports', 'Campaigns', 'Portals', 'Settings'
 *
 * Se o upstream renomear/remover um grupo, este arquivo continua válido —
 * `name`s desconhecidos são ignorados silenciosamente.
 */
export const sidebarConfig = {
  /**
   * Grupos de primeiro nível que NÃO devem aparecer na sidebar.
   * Comente/descomente conforme o que você vende neste fork.
   */
  hiddenTopLevel: [
    'Captain',
    'Portals',
    // 'Campaigns',
  ],

  /**
   * Subitens a esconder dentro de um grupo de primeiro nível (o grupo em si
   * continua visível). Chaves e valores usam o campo `name` de cada item em
   * `Sidebar.vue` → `menuItems`.
   *
   * - Chave = nome do grupo de topo → esconde esses `name`s em qualquer
   *   profundidade abaixo dele (filho direto ou subgrupo inteiro).
   * - Chave com ponto (`Grupo.Subgrupo`) → esconde só entre os filhos
   *   imediatos daquele subgrupo (útil para itens dinâmicos, ex. pastas).
   *
   * Exemplos (Conversation):
   *   'All', 'Mentions', 'Participating', 'Unattended',
   *   'Folders', 'Teams', 'Channels', 'Labels'
   *
   * Exemplos (Settings):
   *   'Settings Billing', 'Settings Audit Logs', 'Settings Sla', …
   *
   * Exemplos (WlAi):
   *   'WlAiPlayground', 'WlAiFaqs', 'WlAiSettings'
   */
  hiddenChildren: {
    // Conversation: ['Mentions', 'Participating', 'Teams'],
    Settings: ['Settings Custom Roles', 'Settings Sla', 'Settings Security'],
  },

  /**
   * Seções rotuladas. Cada entrada vira um rótulo discreto acima do primeiro
   * item dela na sidebar (ex.: "ATENDIMENTO", "CRM", "ADMIN").
   *
   * - A ordem das seções aqui DEFINE a ordem dos grupos na sidebar (quando
   *   `sections` está preenchido, ele tem precedência sobre `order`).
   * - `name`s declarados em `sections` mas escondidos por `hiddenTopLevel`,
   *   ou que o upstream removeu, são pulados.
   * - Itens que existem na sidebar do upstream mas não foram declarados em
   *   nenhuma seção aparecem ao final, sem rótulo.
   *
   * Para desligar as seções e voltar à lista plana, defina `sections: null`.
   */
  sections: [
    {
      label: 'ATENDIMENTO',
      items: ['Inbox', 'Conversation', 'Captain', 'WlAi'],
    },
    {
      label: 'CRM',
      items: [
        'Contacts',
        'Companies',
        'CrmPipelineDeals',
        'CrmPipelineTasks',
        'CrmPipelineSettings',
      ],
    },
    { label: 'ADMIN', items: ['Portals', 'Reports', 'Campaigns', 'Settings'] },
  ],

  /**
   * Ordem desejada quando `sections` é `null`. `name`s presentes aqui
   * aparecem primeiro; os demais mantêm a ordem original do upstream.
   */
  order: null,

  /**
   * Tema visual da sidebar. Adiciona apenas uma classe `wl-sidebar--<theme>`
   * no `<aside>`; o template do upstream não é tocado.
   *
   *   'upstream' — sem tema do fork (visual igual ao Chatwoot, com a paleta
   *                de marca aplicada via `_brand-overrides.scss`).
   *   'contrast' — sidebar com fundo escuro mesmo em light mode.
   *   'accent'   — barra vertical na primária do item ativo + tint sutil.
   */
  theme: 'contrast',

  /**
   * Quando `true`, o account switcher (troca de empresa) e a search saem do
   * topo da sidebar e migram para um topbar customizado (`WlTopBar.vue`)
   * acima do `<main>` no `Dashboard.vue`. A sidebar fica como nav rail pura
   * (logo no topo + menu + profile no fim).
   *
   * Setar para `false` reverte instantaneamente ao layout upstream, sem
   * remover o componente nem o patch.
   */
  useTopBar: true,
};
