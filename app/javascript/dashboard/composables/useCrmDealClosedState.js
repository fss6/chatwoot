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

const closedStageType = deal => deal?.stage?.stage_type;

export const isCrmDealDraggable = deal => !isCrmClosedStage(deal?.stage);

export const useCrmDealClosedState = dealRef => {
  const stageType = computed(() => closedStageType(unref(dealRef)));
  const status = computed(() => unref(dealRef)?.status);

  const isWon = computed(() => {
    if (stageType.value) return stageType.value === 'won';
    return status.value === 'won';
  });

  const isLost = computed(() => {
    if (stageType.value) return stageType.value === 'lost';
    return status.value === 'lost';
  });

  const isClosed = computed(() => isWon.value || isLost.value);
  const isReadOnly = computed(() => isClosed.value);

  return {
    isWon,
    isLost,
    isClosed,
    isReadOnly,
  };
};
