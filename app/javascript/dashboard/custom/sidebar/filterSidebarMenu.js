import { sidebarConfig } from './sidebarConfig';

/**
 * Aplica as customizações deste fork (esconder, reordenar, seccionar) sobre o
 * array de `menuItems` produzido pelo `Sidebar.vue` do upstream.
 *
 * Mantém os objetos originais — só filtra, reordena e, no caso de `sections`,
 * anexa o atributo `data-section-start` no PRIMEIRO item de cada seção. A
 * chave precisa ser a forma kebab-case literal porque Vue 3 passa atributos
 * não declarados como props direto para `setAttribute`, sem normalizar
 * camelCase em data-*.
 *
 * Vue propaga `data-section-start` via fallthrough até o `<li>` raiz do
 * `SidebarGroup`, e o CSS em `_sidebar-theme.scss` desenha o rótulo via
 * `[data-section-start]::before`.
 *
 * @param {Array<{ name: string }>} items
 * @returns {Array}
 */
const applySections = (items, sections) => {
  const byName = new Map(items.map(item => [item.name, item]));
  const ordered = [];

  sections.forEach(section => {
    let isFirstInSection = true;
    (section.items || []).forEach(name => {
      if (!byName.has(name)) return;
      const item = byName.get(name);
      if (isFirstInSection) {
        ordered.push({ ...item, 'data-section-start': section.label });
        isFirstInSection = false;
      } else {
        ordered.push(item);
      }
      byName.delete(name);
    });
  });

  return [...ordered, ...byName.values()];
};

const applyOrder = (items, order) => {
  const remaining = new Map(items.map(item => [item.name, item]));
  const ordered = [];

  order.forEach(name => {
    if (remaining.has(name)) {
      ordered.push(remaining.get(name));
      remaining.delete(name);
    }
  });

  return [...ordered, ...remaining.values()];
};

export function filterSidebarMenu(items) {
  const hidden = new Set(sidebarConfig.hiddenTopLevel || []);
  const filtered = items.filter(item => !hidden.has(item.name));

  if (
    Array.isArray(sidebarConfig.sections) &&
    sidebarConfig.sections.length > 0
  ) {
    return applySections(filtered, sidebarConfig.sections);
  }

  if (Array.isArray(sidebarConfig.order) && sidebarConfig.order.length > 0) {
    return applyOrder(filtered, sidebarConfig.order);
  }

  return filtered;
}
