import { DatabaseContext } from '@/application/database-yjs';
import { useCalendarSetup } from '@/components/database/calendar/Calendar.hooks';
import { Toolbar, Event } from '@/components/database/components/calendar';
import React, { useContext } from 'react';
import { Calendar as BigCalendar } from 'react-big-calendar';
import './calendar.scss';

export function Calendar ({ onRendered }: {
  onRendered?: () => void;
}) {
  const { dayPropGetter, localizer, formats, events, emptyEvents } = useCalendarSetup();
  const scrollLeft = useContext(DatabaseContext)?.scrollLeft;

  return (
    <div
      style={{
        marginInline: scrollLeft === undefined ? undefined : scrollLeft,
      }}
      className={`database-calendar z-[1] h-fit mx-24 max-sm:!mx-6 border-t border-line-divider pb-36 pt-4 text-sm`}
    >
      <BigCalendar
        components={{
          toolbar: (props) => <Toolbar {...props} emptyEvents={emptyEvents} />,
          eventWrapper: Event,
        }}
        onView={onRendered}
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
