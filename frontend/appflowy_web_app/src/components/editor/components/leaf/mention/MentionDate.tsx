import { renderDate } from '@/utils/time';
import React, { useMemo } from 'react';
import { ReactComponent as DateSvg } from '@/assets/date.svg';
import { ReactComponent as ReminderSvg } from '@/assets/reminder_clock.svg';

function MentionDate({ date, reminder }: { date: string; reminder?: { id: string; option: string } }) {
  const dateFormat = useMemo(() => {

    return renderDate(date, 'MMM D, YYYY');
  }, [date]);

  return (
    <span className={'mention-inline gap-0 opacity-70 items-center'} style={{
      color: reminder ? 'var(--fill-default)' : 'var(--text-title)',
    }}>
      <span className={'mention-content px-0 ml-0'}><span>@</span>{dateFormat}</span>
      {reminder ? <ReminderSvg/> : <DateSvg/>}

    </span>
  );
}

export default MentionDate;
