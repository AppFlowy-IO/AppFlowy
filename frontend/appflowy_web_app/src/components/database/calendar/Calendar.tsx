import { AFScroller } from '@/components/_shared/scroller';
import { useCalendarSetup } from '@/components/database/calendar/Calendar.hooks';
import { Toolbar, Event } from '@/components/database/components/calendar';
import React from 'react';
import { Calendar as BigCalendar } from 'react-big-calendar';
import './calendar.scss';

export function Calendar() {
  const { dayPropGetter, localizer, formats, events, emptyEvents } = useCalendarSetup();

  return (
    <AFScroller className={'appflowy-calendar'}>
      <div className={'h-full max-h-[960px] min-h-[560px] px-24 py-4 max-md:px-4'}>
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
    </AFScroller>
  );
}

export default Calendar;
