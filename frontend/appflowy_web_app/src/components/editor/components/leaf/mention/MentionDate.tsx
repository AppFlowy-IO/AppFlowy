import { renderDate } from '@/utils/time';
import React, { useMemo } from 'react';
import { ReactComponent as DateSvg } from '@/assets/date.svg';
import { ReactComponent as ReminderSvg } from '@/assets/clock_alarm.svg';

function MentionDate ({ date, reminder }: { date: string; reminder?: { id: string; option: string } }) {
  const dateFormat = useMemo(() => {
    return renderDate(date, 'MMM D, YYYY');
  }, [date]);

  return (
    <span className={'mention-inline'}>
      <span className={'mention-content mr-[1.5em]'}>@{dateFormat}</span>
      {reminder ? <ReminderSvg className={'mention-icon right-1'} /> : <DateSvg className={'mention-icon right-1'} />}

    </span>
  );
}

export default MentionDate;
