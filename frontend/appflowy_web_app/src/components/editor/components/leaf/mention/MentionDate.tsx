import { renderDate } from '@/utils/time';
import React, { useMemo } from 'react';
import { ReactComponent as DateSvg } from '@/assets/date.svg';
import { ReactComponent as ReminderSvg } from '@/assets/reminder_clock.svg';

function MentionDate({ date, reminder }: { date: string; reminder?: { id: string; option: string } }) {
  console.log('date', date);
  const dateFormat = useMemo(() => {

    return renderDate(date, 'MMM D, YYYY');
  }, [date]);

  return (
    <span className={'mention-inline opacity-70'} style={{
      color: reminder ? 'var(--fill-default)' : 'var(--text-title)',
    }}>
      <span className={'mention-content mr-[1.5em] ml-0'}><span>@</span>{dateFormat}</span>
      {reminder ? <ReminderSvg className={'mention-icon right-1'}/> : <DateSvg className={'mention-icon right-1'}/>}

    </span>
  );
}

export default MentionDate;
