# Customizations

Este documento registra todas as customizações aplicadas neste fork sobre o
upstream do Chatwoot (`https://github.com/chatwoot/chatwoot`). É a memória
institucional usada em cada sync com upstream — antes de aceitar um merge,
verifique esta lista e confirme que nada quebrou.

## Estrutura de remotes

- `origin` → `git@github.com:fss6/chatwoot.git` (este fork; branch principal `main`)
- `upstream` → `https://github.com/chatwoot/chatwoot.git` (oficial; branch base `develop`)

A branch `main` deste fork é derivada de `upstream/develop`. Todo trabalho
white-label vive em `main` (ou em feature branches que mesclam em `main`).

## Sync com upstream

Feito manualmente pela UI do GitHub (botão "Sync fork" no `fss6/chatwoot`).
Quando o sync trouxer commits novos, criar localmente uma branch a partir de
`origin/main` atualizado e abrir PR para revisão.

Sequência recomendada localmente:

```
git fetch origin
git checkout -b sync/<data> origin/main
# resolver conflitos (rerere ajuda — já habilitado neste clone)
git push origin sync/<data>
```

Antes de mesclar:

1. Conferir conflitos (rerere lembra resoluções anteriores).
2. Rodar a suíte: `pnpm eslint && pnpm test && bundle exec rubocop && bundle exec rspec`.
3. Smoke test manual em staging: login, conversa, widget, portal.
4. Conferir que esta lista (`CUSTOMIZATIONS.md`) continua coerente.

## Convenções

- Customizações **novas** moram em arquivos novos (ex.: `app/javascript/dashboard/custom/`,
  `*_brand-overrides.scss`) para minimizar área de conflito.
- Quando precisar editar um arquivo do upstream, mantenha a edição **cirúrgica**:
  uma linha de `@import`, uma troca de paleta, etc.
- Em strings de marca, prefira o composable `useBranding.replaceInstallationName`
  em vez de hardcodar marca nova nos JSONs de i18n.
- i18n: editar apenas `en.yml` e `en.json`. Outros idiomas via overlay próprio
  para não brigar com o Crowdin do upstream.

## Customizações ativas

> Esta seção é atualizada a cada PR de customização. Use a tabela como índice.

| Categoria | Arquivos tocados | Tipo | Motivo |
|---|---|---|---|
| Brand overrides (dashboard) | `app/javascript/dashboard/assets/scss/_brand-overrides.scss` | NEW | Indigo em `--blue-*`; tokens de **superfície** (`--background-color`, `--surface-*`, `--border-*`, `--card-color`, `--solid-*`) para mais contraste canvas/cards; `@import` de `sidebar-theme`, `content-theme` e `conversation-theme`. |
| Brand overrides (dashboard wiring) | `app/javascript/dashboard/assets/scss/_woot.scss` | PATCH | Adicionada 1 linha `@import 'brand-overrides';` após `next-colors`. |
| Brand overrides (widget) | `app/javascript/widget/assets/scss/_brand-overrides.scss` | NEW | Mesma paleta indigo do dashboard para coerência entre superfícies. |
| Brand overrides (widget wiring) | `app/javascript/widget/assets/scss/woot.scss` | PATCH | Adicionada 1 linha `@import 'brand-overrides';` no fim do arquivo, depois das definições embutidas de `:root`/`.dark`. |
| Brand token (`bg-n-brand`) | `theme/colors.js` | PATCH | 1 linha: `brand: '#2781F6'` → `brand: 'rgb(var(--blue-9) / <alpha-value>)'`. Decoupla o token do hex Chatwoot e faz `bg-n-brand` seguir a paleta de `--blue-*` definida no fork. |
| Brand overrides (portal) | `app/javascript/portal/_brand-overrides.scss` | NEW | Reservado para overrides globais do help center (vazio por enquanto; portal usa cor por instância via `@portal.color`). |
| Brand overrides (portal wiring) | `app/javascript/portal/application.scss` | PATCH | Adicionada 1 linha `@import 'brand-overrides';` ao final. |
| Pre-commit hook | `.husky/pre-commit` | PATCH | Roda `./node_modules/.bin/lint-staged` localmente em vez de `npx --no-install`, com fallback para `pnpm exec`. Evita o erro "missing packages: lint-staged" quando `node_modules` foi instalado só no container. |
| lint-staged config | `package.json` | PATCH | Removida a entrada `*.scss: [scss-lint]` (ferramenta não existe mais no projeto — gem `scss_lint` não está no `Gemfile`) e removido o `git add` redundante de `app/**/*.{js,vue}` (lint-staged moderno já comita automaticamente). |
| Sidebar config (white-label) | `app/javascript/dashboard/custom/sidebar/sidebarConfig.js` | NEW | Define `hiddenTopLevel`, `sections` (rótulos por categoria), `order`, `theme` (`upstream` / `contrast` / `accent`) e `useTopBar`. Default atual: `theme: 'contrast'`, `useTopBar: true` — shell escuro permanente. |
| Sidebar filter helper | `app/javascript/dashboard/custom/sidebar/filterSidebarMenu.js` | NEW | Aplica `sidebarConfig` sobre o array de `menuItems`: filtra, ordena por seção e injeta `dataSectionStart` no primeiro item de cada seção. |
| Sidebar theme | `app/javascript/dashboard/custom/sidebar/_sidebar-theme.scss` | NEW | Regras CSS: (1) pill nos rótulos de seção via `[data-section-start]::before`; (2) estado ativo com tint indigo + barra lateral (`nav .bg-n-alpha-2`); (3) tema `contrast` (shell escuro); (4) tema `accent`; (5) alinhamento do dropdown da conta no topbar (`.wl-account-switcher`). |
| Sidebar wiring | `app/javascript/dashboard/components-next/sidebar/Sidebar.vue` | PATCH | Edição cirúrgica: 2 imports do fork + variáveis `wlSidebarThemeClass`/`wlUseTopBar`; troca `return [` por `const items = [` no `computed menuItems`; `return filterSidebarMenu(items);` antes do `});`; injeta `wlSidebarThemeClass` no `:class` do `<aside>`; adiciona 1 `<template v-if="wlUseTopBar">` no header da sidebar e 1 `v-if="!wlUseTopBar"` no row de search+compose para esconde-los quando o topbar custom assume. Conflito em sync apenas se o upstream reescrever o `<aside>` ou o `menuItems`. |
| Sidebar theme wiring | `app/javascript/dashboard/assets/scss/_brand-overrides.scss` | PATCH | Importa `sidebar-theme`, `content-theme` e `conversation-theme` após o `@layer base` de cores. |
| Conteúdo interno (canvas) | `app/javascript/dashboard/custom/content/_content-theme.scss` | NEW | Gradiente + `box-shadow` interno em `main.wl-content` (área principal do dashboard). |
| Conversas (lista + painel + bolhas + composer) | `app/javascript/dashboard/custom/conversation/_conversation-theme.scss` | NEW | Elevação via `box-shadow` em `.conversations-list-wrap`, `.conversation-details-wrap`, `.conversation-panel`, bolhas `.left-bubble`/`.right-bubble`, `.reply-box`; hover nas linhas `.conversation` da lista; seletores RTL com `#app[dir='rtl']` + `.dark #app[dir='rtl']`. |
| Tailwind shadows (fork) | `tailwind.config.js` | PATCH | `theme.extend.boxShadow` — `sm`/`md`/`lg`/`xl`/`2xl`/`inner`/`DEFAULT` mais marcados que o default Tailwind (afeta componentes com `shadow-*`). |
| Topbar custom (white-label) | `app/javascript/dashboard/custom/topbar/WlTopBar.vue` | NEW | Topbar acima do `<main>` com search + ComposeConversation + `SidebarAccountSwitcher`. Wrapper `.wl-account-switcher` marca o switcher para alinhar o dropdown à direita via CSS. Classe `wl-topbar--contrast` no `<header>`. |
| Account switcher dropdown align (CSS) | `app/javascript/dashboard/custom/sidebar/_sidebar-theme.scss` | NEW (regra) | Posiciona as duas camadas absolutas aninhadas do `DropdownContainer` ao `inset-inline-end: 0` dentro de `.wl-account-switcher`. Zero patch upstream. |
| Topbar mounting | `app/javascript/dashboard/routes/dashboard/Dashboard.vue` | PATCH | Importa `WlTopBar` + `sidebarConfig`; expõe `wlUseTopBar` no setup; envolve `<main>` num wrapper coluna (`flex flex-col flex-1`) com `<WlTopBar v-if="wlUseTopBar" />` no topo; `<main>` com classe `wl-content`. |

### Tipos

- **NEW** — arquivo criado neste fork. Zero conflito esperado em sync.
- **PATCH** — edição cirúrgica em arquivo do upstream. Conflito possível.
- **WRAP** — wrapper que substitui o uso de um componente do upstream sem editá-lo.

## Tags de release

Convenção: `vX.Y.Z-fss6.N` onde `X.Y.Z` é a versão upstream de referência e
`N` é incremental por release deste fork.

- `v0.1.0-fss6.0` — baseline (Fase 0).
- `v0.1.1-fss6.0` — Fase 2 scaffold: arquivos `_brand-overrides.scss` criados em dashboard/widget/portal, prontos para receber a paleta da marca.
- `v0.1.2-fss6.0` — Fase 2 paleta Violet (Radix) aplicada em dashboard e widget. (Substituída na v0.1.5.)
- `v0.1.3-fss6.0` — Sidebar config: ponto de extensão `sidebarConfig.js` para esconder/reordenar grupos sem editar `Sidebar.vue`.
- `v0.1.4-fss6.0` — Sidebar theme: temas `contrast` e `accent` disponíveis via `sidebarConfig.theme`. (Tema default revertido em v0.1.5.)
- `v0.1.5-fss6.0` — Paleta trocada para **slate sóbria** (Linear/Vercel) em dashboard e widget; sidebar volta ao tema `upstream`. Adicionadas **seções rotuladas** (ATENDIMENTO / CRM / INSIGHTS / ADMIN) via `sidebarConfig.sections` — disposição da sidebar deixa de ser lista plana. Zero patch novo no template do upstream (usa data-attribute + CSS).
- `v0.1.6-fss6.0` — **Topbar custom** (`WlTopBar.vue`) acima do `<main>` com search + nova conversa + account switcher. Sidebar vira **nav rail pura** (logo no topo + menu + profile). Acionado por `sidebarConfig.useTopBar = true` — desligar reverte ao layout upstream sem remover código. Divider das seções ganha **barra colorida de 2px** na primária acima do label.
- `v0.1.7-fss6.0` — Paleta trocada de slate puro para **slate + indigo acento** (Linear-ish). `--blue-*` agora é Indigo Radix; `bg-n-brand` (botões primários) passa a obedecer ao fork via patch de 1 linha em `theme/colors.js`. Section pill da sidebar fica **monocromático com `inset` outline** (mais visível). Estado ativo da sidebar ganha **tint indigo + barra lateral** ("brilho" do fork) aplicado em `nav .bg-n-alpha-2` (atenção: classe exata, não substring — caso contrário casa `hover:bg-n-alpha-2` em todo item).
- `v0.1.9-fss6.0` — **Tema de conteúdo interno**: tokens de superfície/borda em `_brand-overrides.scss`; `theme.extend.boxShadow` no Tailwind (sombras mais fortes em `shadow-sm` etc.); `main.wl-content` + `_content-theme.scss` (gradiente perceptível no canvas principal).
- `v0.1.10-fss6.0` — **Tema da área de conversas**: `_conversation-theme.scss` importado em `_brand-overrides.scss` — sombras na coluna da lista, no painel de detalhe, nas bolhas e no composer (`reply-box`), com variantes dark e RTL.

## Gotchas conhecidos

> Atualizar quando algum sync ensinar uma lição nova.

- (vazio por enquanto)

## Estado atual do trabalho (handoff)

### Fases concluídas

- **Fase 0 — Setup de fork e pipeline** ✓
  - Remote `origin` → `git@github.com:fss6/chatwoot.git`.
  - Remote `upstream` → `https://github.com/chatwoot/chatwoot.git`.
  - Branch `main` criada a partir de `upstream/develop` e empurrada para `origin/main`.
  - `git config rerere.enabled true` e `rerere.autoupdate true`.
  - Sync com upstream feito manualmente via UI do GitHub no fork (sem workflow dedicado).
- **Fase 2 — Sistema de cores** ✓
  - Três arquivos `_brand-overrides.scss` criados em dashboard/widget/portal e conectados via `@import` no SCSS entry de cada superfície.
  - Paleta primária aplicada: **Violet (Radix Colors)** no lugar do azul do Chatwoot, em dashboard e widget, light e dark mode.
  - Cores semânticas (`ruby`, `amber`, `teal`) mantidas para preservar leitura crítica de SLA/CSAT/erros.
  - Portal continua com paleta neutra (sem cor de marca global); cor por portal segue dinâmica via `@portal.color`.

### Pendências para o próximo bloco de trabalho

1. **Commit das mudanças** (Fases 0 + 2 scaffold). Hoje no working tree:
   - `M docker-compose.yaml` (modificação antiga, não relacionada ao white-label).
   - `M app/javascript/dashboard/assets/scss/_woot.scss`
   - `M app/javascript/portal/application.scss`
   - `M app/javascript/widget/assets/scss/woot.scss`
   - `?? CUSTOMIZATIONS.md`
   - `?? app/javascript/dashboard/assets/scss/_brand-overrides.scss`
   - `?? app/javascript/portal/_brand-overrides.scss`
   - `?? app/javascript/widget/assets/scss/_brand-overrides.scss`
   - Sugestão: commit separado para `docker-compose.yaml` (ou descartar) antes do commit do white-label.

2. **Decisão pendente sobre Sidebar (Fase 4)**: descoberta importante registrada abaixo, na seção "Descobertas". Em vez de criar um wrapper amplo, primeiro responder:
   - Quais módulos esconder no MVP (Captain? Campaigns? Help Center?).
   - Se quer reordenar/renomear grupos.
   - Se quer wrapper completo agora ou só após decidir features.

3. **Paleta a definir antes de preencher os overrides**. Pendente decisão de
   cor primária do produto. Quando decidido:
   - Preencher `--blue-9`, `--blue-10`, `--blue-11` em `_brand-overrides.scss` do dashboard (`:root` claro + `.dark` escuro).
   - Replicar no widget para coerência.
   - Se quiser substituir totalmente a paleta `woot.*` do Tailwind (ex.: para classes `bg-woot-500`), editar também `theme/colors.js`.

4. **Próximas fases não iniciadas** (ordem sugerida no plano original):
   - Fase 1 — Branding runtime (Super Admin + corrigir hardcodes em `public/manifest.json` e `app/views/layouts/vueapp.html.erb`).
   - Fase 3 — Substituir assets (logos, favicons, splash).
   - Fase 4 — Layout: wrapper de Sidebar e ajuste de help URLs.
   - Fase 5 — Widget (POWERED_BY hardcoded + auditoria).
   - Fase 6 — Help Center (auditar header + considerar `disable_branding` por padrão).
   - Fase 7 — i18n: substituir "Chatwoot" hardcoded em `en.yml` e `en.json`.

### Descobertas relevantes

A flag `isACustomBrandedInstance` em [`app/javascript/shared/store/globalConfig.js`](app/javascript/shared/store/globalConfig.js) já é `installationName !== 'Chatwoot'`. Setando `INSTALLATION_NAME` no Super Admin para qualquer coisa diferente de "Chatwoot", os itens abaixo **somem sem código**:

| Elemento | Onde |
|---|---|
| Changelog card e button da Sidebar | `app/javascript/dashboard/components-next/sidebar/Sidebar.vue` linhas 839-852 |
| Banner Year-in-Review | `app/javascript/dashboard/components-next/year-in-review/YearInReviewBanner.vue` |
| "Contact support", "Docs", "Changelog" no profile menu | `app/javascript/dashboard/components-next/sidebar/SidebarProfileMenu.vue` |
| Telas de paywall/upgrade | `app/javascript/dashboard/composables/usePolicy.js` linhas 75-77, 111-113 |
| Variações de copy/testimonials no signup | `app/javascript/v3/views/auth/signup/Index.vue` |

**Implicação:** muitos dos itens do plano original "Fase 4" são na verdade Fase 1 (configuração runtime, zero código).
