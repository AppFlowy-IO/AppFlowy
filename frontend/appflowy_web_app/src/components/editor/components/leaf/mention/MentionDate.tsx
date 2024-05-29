import { renderDate } from '@/utils/time';
import React, { useMemo } from 'react';
import { ReactComponent as DateSvg } from '$icons/16x/date.svg';
import { ReactComponent as ReminderSvg } from '$icons/16x/clock_alarm.svg';

function MentionDate({ date, reminder }: { date: string; reminder?: { id: string; option: string } }) {
  const dateFormat = useMemo(() => {
    return renderDate(date, 'MMM D, YYYY');
  }, [date]);

  return (
    <span className={'mention-inline'}>
      {reminder ? <ReminderSvg className={'mention-icon'} /> : <DateSvg className={'mention-icon'} />}

      <span className={'mention-content'}>{dateFormat}</span>
    </span>
  );
}

export default MentionDate;
