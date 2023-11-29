import React from 'react';
import { LocalizationProvider } from '@mui/x-date-pickers-pro';
import { AdapterDayjs } from '@mui/x-date-pickers-pro/AdapterDayjs';
import DateTimeInput from '$app/components/database/components/field_types/date/DateTimeInput';

interface Props {
  onChange: (params: { date?: number; endDate?: number; time?: string; endTime?: string }) => void;
  date?: number;
  endDate?: number;
  time?: string;
  endTime?: string;
  isRange?: boolean;
  timeFormat: string;
  dateFormat: string;
  includeTime?: boolean;
}
function DateTimeSet({ onChange, date, endDate, time, endTime, isRange, timeFormat, dateFormat, includeTime }: Props) {
  return (
    <LocalizationProvider dateAdapter={AdapterDayjs}>
      <DateTimeInput
        onChange={({ date, time }) => {
          onChange({
            date,
            time,
          });
        }}
        date={date}
        time={time}
        timeFormat={timeFormat}
        dateFormat={dateFormat}
        includeTime={includeTime}
      />
      {isRange && (
        <DateTimeInput
          date={endDate}
          time={endTime}
          onChange={({ date, time }) => {
            onChange({
              endDate: date,
              endTime: time,
            });
          }}
          timeFormat={timeFormat}
          dateFormat={dateFormat}
          includeTime={includeTime}
        />
      )}
    </LocalizationProvider>
  );
}

export default DateTimeSet;
