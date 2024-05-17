import { FieldId } from '@/application/collab.type';
import { useDateTypeCellDispatcher } from '@/components/database/components/cell/Cell.hooks';
import { DateTimeCell } from '@/components/database/components/cell/cell.type';
import React, { useMemo } from 'react';
import { ReactComponent as ReminderSvg } from '$icons/16x/clock_alarm.svg';

export default function ({ cell, fieldId }: { cell?: DateTimeCell; rowId: string; fieldId: FieldId }) {
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

  return (
    <div className={'flex cursor-text items-center gap-1'}>
      {hasReminder && <ReminderSvg className={'h-4 w-4'} />}
      {dateStr}
    </div>
  );
}
