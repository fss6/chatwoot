import { useI18n } from 'vue-i18n';
import { formatDistanceToNow, fromUnixTime } from 'date-fns';
import { enUS, ptBR } from 'date-fns/locale';

const DATE_FNS_LOCALES = {
  en: enUS,
  pt_BR: ptBR,
  pt: ptBR,
};

export const useCrmNotePresentation = () => {
  const { t, locale } = useI18n();

  const formatNoteTime = createdAt => {
    if (!createdAt) return '';
    const dateFnsLocale = DATE_FNS_LOCALES[locale.value] || enUS;
    return formatDistanceToNow(fromUnixTime(createdAt), {
      addSuffix: true,
      locale: dateFnsLocale,
    });
  };

  const authorLabel = (note, currentUserId) => {
    if (note?.user?.id === currentUserId) {
      return t('CRM_PIPELINE.DEAL.NOTES_YOU');
    }
    return note?.user?.name || 'Bot';
  };

  return { formatNoteTime, authorLabel };
};
