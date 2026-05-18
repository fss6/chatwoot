import { computed, unref } from 'vue';
import { formatDistanceToNow, fromUnixTime, isValid, parseISO } from 'date-fns';
import { shortTimestamp } from 'shared/helpers/timeHelper';

export const formatDealClosedAtLabel = closedAt => {
  if (!closedAt) return null;

  const date =
    typeof closedAt === 'number'
      ? fromUnixTime(closedAt)
      : parseISO(String(closedAt));

  if (!isValid(date)) return null;

  return shortTimestamp(formatDistanceToNow(date, { addSuffix: true }));
};

export const isCrmClosedStage = stage =>
  stage?.stage_type === 'lost' || stage?.stage_type === 'won';

export const isCrmStageDropTarget = stage => !isCrmClosedStage(stage);

export const isCrmDealDraggable = deal =>
  deal?.status !== 'lost' && deal?.status !== 'won';

export const useCrmDealClosedState = dealRef => {
  const status = computed(() => unref(dealRef)?.status);

  const isWon = computed(() => status.value === 'won');
  const isLost = computed(() => status.value === 'lost');
  const isClosed = computed(() => isWon.value || isLost.value);
  const isReadOnly = computed(() => isClosed.value);

  return {
    isWon,
    isLost,
    isClosed,
    isReadOnly,
  };
};
