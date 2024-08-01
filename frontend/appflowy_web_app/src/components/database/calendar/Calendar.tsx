import { useCalendarSetup } from '@/components/database/calendar/Calendar.hooks';
import { Toolbar, Event } from '@/components/database/components/calendar';
import React from 'react';
import { Calendar as BigCalendar } from 'react-big-calendar';
import './calendar.scss';

export function Calendar() {
  const { dayPropGetter, localizer, formats, events, emptyEvents } = useCalendarSetup();

  return (
    <div className={'database-calendar h-fit  pb-4 pt-4 text-sm'}>
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
