import dayjs from 'dayjs';
import React, { useMemo } from 'react';
import { ReactComponent as DateSvg } from '@/assets/date.svg';

function MentionDate({ date }: { date: string }) {
  const dateFormat = useMemo(() => {
    return dayjs(date).format('MMM D, YYYY');
  }, [date]);

  return (
    <span className={'mention-inline'}>
      <DateSvg className={'mention-icon'} />
      <span className={'mention-content'}>{dateFormat}</span>
    </span>
  );
}

export default MentionDate;
