import React from 'react';
import { Calendar as BigCalendar, dayjsLocalizer } from 'react-big-calendar';
import dayjs from 'dayjs';
import './calendar.scss';

const localizer = dayjsLocalizer(dayjs);

export function Calendar() {
  return (
    <div className={'max-ms:px-4 px-24 py-4'}>
      <BigCalendar localizer={localizer} startAccessor='start' endAccessor='end' style={{ height: 500 }} />
    </div>
  );
}

export default Calendar;
