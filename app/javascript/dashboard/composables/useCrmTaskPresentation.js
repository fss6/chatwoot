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

export const taskTypeIcon = taskType =>
  CRM_TASK_TYPE_ICONS[taskType] || CRM_TASK_TYPE_ICONS.other;

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
    const diff = Math.floor(
      (Date.now() - new Date(dueAt).getTime()) / 86400000
    );
    return diff > 0 ? diff : null;
  };

  return {
    dueLabelFromDueAt,
    daysOverdue,
    taskTypeIcon,
  };
};
