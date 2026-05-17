import { computed, unref } from 'vue';
import { useI18n } from 'vue-i18n';
import { differenceInDays, startOfDay } from 'date-fns';

export const temperatureConfig = {
  cold: {
    labelKey: 'COLD',
    badgeClass: 'border border-n-blue-4 bg-n-blue-3 text-n-blue-11',
    icon: 'i-lucide-flame',
  },
  warm: {
    labelKey: 'WARM',
    badgeClass: 'border border-n-amber-4 bg-n-amber-3 text-n-amber-11',
    icon: 'i-lucide-flame',
  },
  hot: {
    labelKey: 'HOT',
    badgeClass: 'border border-n-ruby-4 bg-n-ruby-3 text-n-ruby-11',
    icon: 'i-lucide-flame',
  },
};

export const initialsFromName = name => {
  if (!name) return '';
  return name
    .split(' ')
    .filter(Boolean)
    .slice(0, 2)
    .map(part => part[0])
    .join('')
    .toUpperCase();
};

export const contactCompanyName = contact =>
  contact?.company_name?.trim() || '';

export const contactCardSubtitle = contact =>
  contactCompanyName(contact) || contact?.name || '';

const overdueDaysFromDueAt = dueAt => {
  if (!dueAt) return 0;
  const dueDate = startOfDay(new Date(dueAt));
  const today = startOfDay(new Date());
  const diff = differenceInDays(today, dueDate);
  return Math.max(diff, 1);
};

const dueLabelFromDueAt = (dueAt, t) => {
  if (!dueAt) return null;
  const dueDate = startOfDay(new Date(dueAt));
  const today = startOfDay(new Date());
  const diff = differenceInDays(dueDate, today);
  if (diff === 0) return t('CRM_PIPELINE.DEAL.DUE_TODAY');
  if (diff === 1) return t('CRM_PIPELINE.DEAL.DUE_TOMORROW');
  return new Date(dueAt).toLocaleDateString(undefined, {
    month: 'short',
    day: 'numeric',
  });
};

export function useCrmDealCardPresentation(dealRef) {
  const { t } = useI18n();

  const deal = computed(() => unref(dealRef));

  const formattedAmount = computed(() => {
    const dealValue = deal.value;
    if (!dealValue?.amount) return null;
    return new Intl.NumberFormat(undefined, {
      style: 'currency',
      currency: dealValue.currency || 'BRL',
      minimumFractionDigits: 2,
      maximumFractionDigits: 2,
    }).format(dealValue.amount);
  });

  const showValueRow = computed(() =>
    Boolean(formattedAmount.value || deal.value?.lead_temperature)
  );

  const temperature = computed(() => {
    const key = deal.value?.lead_temperature;
    const config = temperatureConfig[key];
    if (!config) return null;
    return {
      label: t(`CRM_PIPELINE.DEAL.${config.labelKey}`),
      badgeClass: config.badgeClass,
      icon: config.icon,
    };
  });

  const footerIsDanger = computed(() => {
    const d = deal.value;
    return Boolean(
      d?.next_task?.is_overdue || d?.no_next_step || !d?.next_task?.title
    );
  });

  const footerStatusText = computed(() => {
    const d = deal.value;
    if (d?.next_task?.is_overdue) {
      const days = overdueDaysFromDueAt(d.next_task.due_at);
      return days === 1
        ? t('CRM_PIPELINE.DEAL.DAYS_OVERDUE_ONE')
        : t('CRM_PIPELINE.DEAL.DAYS_OVERDUE', { count: days });
    }
    if (d?.no_next_step) return t('CRM_PIPELINE.DEAL.NO_NEXT_STEP');
    if (d?.next_task?.title) {
      const dueLabel = dueLabelFromDueAt(d.next_task.due_at, t);
      return dueLabel
        ? `${d.next_task.title} · ${dueLabel}`
        : d.next_task.title;
    }
    return t('CRM_PIPELINE.DEAL.NO_NEXT_STEP');
  });

  const footerStatusClasses = computed(() =>
    footerIsDanger.value ? 'font-semibold text-n-ruby-11' : 'text-n-slate-11'
  );

  const contactSubtitle = computed(() =>
    contactCardSubtitle(deal.value?.contact)
  );

  const assigneeName = computed(
    () => deal.value?.assigned_user?.name || t('CRM_PIPELINE.DEAL.UNASSIGNED')
  );

  const assigneeInitials = computed(() =>
    initialsFromName(deal.value?.assigned_user?.name)
  );

  return {
    formattedAmount,
    showValueRow,
    temperature,
    footerStatusText,
    footerStatusClasses,
    footerIsDanger,
    contactSubtitle,
    assigneeName,
    assigneeInitials,
  };
}

export function formatStageTotal(deals, currency = 'BRL') {
  const total = deals.reduce(
    (sum, deal) => sum + (Number(deal.amount) || 0),
    0
  );
  if (!total) return null;
  return new Intl.NumberFormat(undefined, {
    style: 'currency',
    currency: deals.find(d => d.currency)?.currency || currency,
    maximumFractionDigits: 0,
  }).format(total);
}
