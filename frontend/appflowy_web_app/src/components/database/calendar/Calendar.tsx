import { useDatabaseContext } from '@/application/database-yjs';
import { useCalendarSetup } from '@/components/database/calendar/Calendar.hooks';
import { Toolbar, Event } from '@/components/database/components/calendar';
import React, { useEffect, useRef } from 'react';
import { Calendar as BigCalendar } from 'react-big-calendar';
import './calendar.scss';

export function Calendar () {
  const { dayPropGetter, localizer, formats, events, emptyEvents } = useCalendarSetup();
  const scrollLeft = useDatabaseContext().scrollLeft;
  const isDocumentBlock = useDatabaseContext().isDocumentBlock;
  const ref = useRef<HTMLDivElement>(null);
  const onRendered = useDatabaseContext().onRendered;

  useEffect(() => {
    const el = ref.current;

    if (!el) return;

    onRendered?.(el.scrollHeight + 60);
  }, [onRendered]);
  return (
    <div
      ref={ref}
      style={{
        marginInline: scrollLeft === undefined ? undefined : scrollLeft,
        marginBottom: isDocumentBlock ? 0 : 156,
      }}
      className={`database-calendar z-[1] h-fit mx-24 max-sm:!mx-6 border-t border-line-divider pt-4 text-sm`}
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
