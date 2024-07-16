import { CalendarEvent } from '@/application/database-yjs';
import { RichTooltip } from '@/components/_shared/popover';
import NoDateRow from '@/components/database/components/calendar/toolbar/NoDateRow';
import React, { useMemo } from 'react';
import { useTranslation } from 'react-i18next';

function NoDate({ emptyEvents }: { emptyEvents: CalendarEvent[] }) {
  const [open, setOpen] = React.useState(false);
  const { t } = useTranslation();
  const content = useMemo(() => {
    return (
      <div className={'flex w-[260px] flex-col gap-3 p-2 text-xs font-medium'}>
        {/*<div className={'text-text-caption'}>{t('calendar.settings.clickToOpen')}</div>*/}
        {emptyEvents.map((event) => {
          const rowId = event.id.split(':')[0];

          return <NoDateRow rowId={rowId} key={event.id} />;
        })}
      </div>
    );
  }, [emptyEvents]);

  return (
    <RichTooltip
      content={content}
      open={open}
      placement={'bottom'}
      onClose={() => {
        setOpen(false);
      }}
    >
      <span
        className={' whitespace-nowrap rounded-md border border-line-divider border-line-divider p-1 px-2'}
        // onClick={() => setOpen(true)}
      >
        {`${t('calendar.settings.noDateTitle')} (${emptyEvents.length})`}
      </span>
    </RichTooltip>
  );
}

export default NoDate;
