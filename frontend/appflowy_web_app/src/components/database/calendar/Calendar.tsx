import { useCalendarSetup } from '@/components/database/calendar/Calendar.hooks';
import { Toolbar, Event } from '@/components/database/components/calendar';
import React from 'react';
import { Calendar as BigCalendar } from 'react-big-calendar';
import './calendar.scss';

export function Calendar() {
  const { dayPropGetter, localizer, formats, events, emptyEvents } = useCalendarSetup();

  return (
    <div className={'appflowy-calendar h-full max-h-[960px]  min-h-[560px] px-16 pt-4 max-md:px-4'}>
      <BigCalendar
        components={{
          toolbar: (props) => <Toolbar {...props} emptyEvents={emptyEvents} />,
          eventWrapper: Event,
        }}
        style={{
          marginBottom: '24px',
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
