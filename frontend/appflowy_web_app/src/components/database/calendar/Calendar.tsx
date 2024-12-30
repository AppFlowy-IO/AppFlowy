import { useDatabaseContext } from '@/application/database-yjs';
import { useCalendarSetup } from '@/components/database/calendar/Calendar.hooks';
import { Toolbar, Event } from '@/components/database/components/calendar';
import { useConditionsContext } from '@/components/database/components/conditions/context';
import { debounce } from 'lodash-es';
import React, { useEffect, useRef } from 'react';
import { Calendar as BigCalendar } from 'react-big-calendar';
import './calendar.scss';

export function Calendar () {
  const { dayPropGetter, localizer, formats, events, emptyEvents } = useCalendarSetup();
  const scrollLeft = useDatabaseContext().scrollLeft;
  const isDocumentBlock = useDatabaseContext().isDocumentBlock;
  const ref = useRef<HTMLDivElement>(null);
  const onRendered = useDatabaseContext().onRendered;
  const conditionsContext = useConditionsContext();
  const expanded = conditionsContext?.expanded ?? false;

  useEffect(() => {
    const el = ref.current;

    if (!el) return;

    const onResize = debounce(() => {
      const conditionHeight = expanded ? el.closest('.appflowy-database')?.querySelector('.database-conditions')?.clientHeight || 0 : 0;
      const offset = conditionHeight + 60;

      onRendered?.(el.scrollHeight + offset);
    }, 200);

    onResize();

    if (!isDocumentBlock) return;
    el.addEventListener('resize', onResize);

    return () => {
      el.removeEventListener('resize', onResize);
    };

  }, [onRendered, expanded, isDocumentBlock]);
  return (
    <div
      ref={ref}
      style={{
        marginInline: scrollLeft === undefined ? undefined : scrollLeft,
        marginBottom: isDocumentBlock ? 0 : 156,
      }}
      className={`database-calendar z-[1] h-fit mx-24 max-sm:!mx-6 pt-4 text-sm`}
    >
      <BigCalendar
        components={{
          toolbar: (props) => <Toolbar {...props} emptyEvents={emptyEvents} />,
          eventWrapper: Event,
        }}
        events={events}
        views={['month']}
        localizer={localizer}
        formats={formats}
        dayPropGetter={dayPropGetter}
        showMultiDayTimes={true}
        step={1}
        showAllEvents={true}
      />
    </div>
  );
}

export default Calendar;
