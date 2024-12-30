import { CalendarEvent } from '@/application/database-yjs';
import NoDate from '@/components/database/components/calendar/toolbar/NoDate';
import { IconButton } from '@mui/material';
import Button from '@mui/material/Button';
import dayjs from 'dayjs';
import React, { useMemo } from 'react';
import { ToolbarProps } from 'react-big-calendar';
import { ReactComponent as LeftArrow } from '$icons/16x/arrow_left.svg';
import { ReactComponent as RightArrow } from '$icons/16x/arrow_right.svg';
import { ReactComponent as DownArrow } from '$icons/16x/arrow_down.svg';

import { useTranslation } from 'react-i18next';

export function Toolbar ({
  onNavigate,
  date,
  emptyEvents,
}: ToolbarProps & {
  emptyEvents: CalendarEvent[];
}) {
  const dateStr = useMemo(() => dayjs(date).format('MMM YYYY'), [date]);
  const { t } = useTranslation();

  return (
    <div className={'flex items-center justify-between overflow-x-auto overflow-y-hidden'}>
      <div className={'whitespace-nowrap text-sm font-medium'}>{dateStr}</div>
      <div className={'flex items-center justify-end gap-2 max-sm:gap-1'}>
        <IconButton size={'small'} onClick={() => onNavigate('PREV')}>
          <LeftArrow />
        </IconButton>
        <Button
          className={'h-6 font-normal max-sm:min-w-fit'}
          size={'small'}
          variant={'text'}
          color={'inherit'}
          onClick={() => onNavigate('TODAY')}
        >
          {t('calendar.navigation.today')}
        </Button>
        <IconButton size={'small'} onClick={() => onNavigate('NEXT')}>
          <RightArrow />
        </IconButton>
        <Button
          size={'small'}
          variant={'outlined'}
          disabled
          className={'rounded-md border-line-divider'}
          color={'inherit'}
          onClick={() => onNavigate('TODAY')}
          endIcon={<DownArrow className={'h-3 w-3 text-text-caption'} />}
        >
          {t('calendar.navigation.views.month')}
        </Button>
        <NoDate emptyEvents={emptyEvents} />
      </div>
    </div>
  );
}

export default Toolbar;
