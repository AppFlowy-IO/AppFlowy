import { useDateTypeCellDispatcher } from '@/components/database/components/cell/Cell.hooks';
import { CellProps, DateTimeCell as DateTimeCellType } from '@/components/database/components/cell/cell.type';
import React, { useMemo } from 'react';
import { ReactComponent as ReminderSvg } from '$icons/16x/clock_alarm.svg';

export function DateTimeCell({ cell, fieldId, style }: CellProps<DateTimeCellType>) {
  const { getDateTimeStr } = useDateTypeCellDispatcher(fieldId);

  const startDateTime = useMemo(() => {
    return getDateTimeStr(cell?.data || '', cell?.includeTime);
  }, [cell, getDateTimeStr]);

  const endDateTime = useMemo(() => {
    if (!cell) return null;
    const { endTimestamp, isRange } = cell;

    if (!isRange) return null;

    return getDateTimeStr(endTimestamp || '', cell?.includeTime);
  }, [cell, getDateTimeStr]);

  const dateStr = useMemo(() => {
    return [startDateTime, endDateTime].filter(Boolean).join(' -> ');
  }, [startDateTime, endDateTime]);

  const hasReminder = !!cell?.reminderId;

  if (!cell?.data) return null;
  return (
    <div style={style} className={'flex cursor-text items-center gap-1'}>
      {hasReminder && <ReminderSvg className={'h-4 w-4'} />}
      {dateStr}
    </div>
  );
}
