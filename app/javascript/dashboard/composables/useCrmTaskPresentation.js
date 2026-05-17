import { useI18n } from 'vue-i18n';
import { differenceInDays, startOfDay } from 'date-fns';

export const CRM_TASK_TYPE_ICONS = {
  call: 'i-lucide-phone',
  meeting: 'i-lucide-calendar',
  follow_up: 'i-lucide-message-circle',
  send_proposal: 'i-lucide-file-text',
  send_contract: 'i-lucide-file-signature',
  payment_check: 'i-lucide-wallet',
  other: 'i-lucide-list-checks',
};

export const CRM_TASK_TYPE_LABEL_KEYS = {
  call: 'CRM_PIPELINE.TASKS.TYPES.call',
  meeting: 'CRM_PIPELINE.TASKS.TYPES.meeting',
  follow_up: 'CRM_PIPELINE.TASKS.TYPES.follow_up',
  send_proposal: 'CRM_PIPELINE.TASKS.TYPES.send_proposal',
  send_contract: 'CRM_PIPELINE.TASKS.TYPES.send_contract',
  payment_check: 'CRM_PIPELINE.TASKS.TYPES.payment_check',
  other: 'CRM_PIPELINE.TASKS.TYPES.other',
};

export const TASK_DUE_TONES = {
  overdue: {
    border: 'border-l-n-ruby-9',
    iconBox: 'bg-n-ruby-3',
    icon: 'text-n-ruby-11',
    text: 'text-n-ruby-11',
  },
  on_time: {
    border: 'border-l-n-teal-9',
    iconBox: 'bg-n-teal-3',
    icon: 'text-n-teal-11',
    text: 'text-n-teal-11',
  },
  none: {
    border: 'border-l-n-strong',
    iconBox: 'bg-n-alpha-2',
    icon: 'text-n-slate-11',
    text: 'text-n-slate-11',
  },
};

export const taskTypeIcon = taskType =>
  CRM_TASK_TYPE_ICONS[taskType] || CRM_TASK_TYPE_ICONS.other;

export const taskDueStatus = (dueAt, isOverdue = false) => {
  if (!dueAt) return 'none';
  if (isOverdue) return 'overdue';

  const diff = differenceInDays(
    startOfDay(new Date(dueAt)),
    startOfDay(new Date())
  );
  if (diff < 0) return 'overdue';
  return 'on_time';
};

export const getTaskDueTone = (dueAt, isOverdue = false) =>
  TASK_DUE_TONES[taskDueStatus(dueAt, isOverdue)] || TASK_DUE_TONES.none;

export const useCrmTaskPresentation = () => {
  const { t } = useI18n();

  const dueLabelFromDueAt = dueAt => {
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

  const daysOverdue = dueAt => {
    if (!dueAt) return null;
    const diff = differenceInDays(
      startOfDay(new Date()),
      startOfDay(new Date(dueAt))
    );
    return diff > 0 ? diff : null;
  };

  const dueStatusLabel = (dueAt, isOverdue = false) => {
    const status = taskDueStatus(dueAt, isOverdue);
    if (status === 'overdue') {
      const days = daysOverdue(dueAt);
      if (!days) return t('CRM_PIPELINE.TASKS.OVERDUE');
      return days === 1
        ? t('CRM_PIPELINE.DEAL.DAYS_OVERDUE_ONE')
        : t('CRM_PIPELINE.DEAL.DAYS_OVERDUE', { count: days });
    }
    if (status === 'on_time') {
      const days = differenceInDays(
        startOfDay(new Date(dueAt)),
        startOfDay(new Date())
      );
      if (days === 0) return t('CRM_PIPELINE.DEAL.DUE_TODAY');
      if (days === 1) return t('CRM_PIPELINE.DEAL.DUE_IN_DAYS_ONE');
      return t('CRM_PIPELINE.DEAL.DUE_IN_DAYS', { count: days });
    }
    return null;
  };

  const taskTypeLabel = taskType => {
    const key =
      CRM_TASK_TYPE_LABEL_KEYS[taskType] || CRM_TASK_TYPE_LABEL_KEYS.other;
    return t(key);
  };

  return {
    dueLabelFromDueAt,
    daysOverdue,
    dueStatusLabel,
    taskTypeIcon,
    taskTypeLabel,
    getTaskDueTone,
    taskDueStatus,
  };
};
