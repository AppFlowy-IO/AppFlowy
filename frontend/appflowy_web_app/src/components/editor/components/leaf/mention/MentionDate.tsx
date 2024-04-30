import { renderDate } from '@/utils/time';
import React, { useMemo } from 'react';
import { ReactComponent as DateSvg } from '@/assets/date.svg';
import { ReactComponent as ReminderSvg } from '@/assets/clock_alarm.svg';

function MentionDate({ date, reminder }: { date: string; reminder?: { id: string; option: string } }) {
  const dateFormat = useMemo(() => {
    return renderDate(date);
  }, [date]);

  return (
    <span className={'mention-inline'}>
      {reminder ? <ReminderSvg className={'mention-icon'} /> : <DateSvg className={'mention-icon'} />}

      <span className={'mention-content'}>{dateFormat}</span>
    </span>
  );
}

export default MentionDate;
