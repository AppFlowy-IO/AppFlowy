import React, { useEffect, useState } from 'react';
import DatePicker, { ReactDatePickerCustomHeaderProps } from 'react-datepicker';
import 'react-datepicker/dist/react-datepicker.css';
import dayjs from 'dayjs';
import { ReactComponent as LeftSvg } from '$app/assets/arrow-left.svg';
import { ReactComponent as RightSvg } from '$app/assets/arrow-right.svg';
import { IconButton } from '@mui/material';
import './calendar.scss';

function CustomCalendar({
  handleChange,
  isRange,
  timestamp,
  endTimestamp,
}: {
  handleChange: (params: { date?: number; endDate?: number }) => void;
  isRange: boolean;
  timestamp?: number;
  endTimestamp?: number;
}) {
  const [startDate, setStartDate] = useState<Date | null>(() => {
    if (!timestamp) return null;
    return new Date(timestamp * 1000);
  });
  const [endDate, setEndDate] = useState<Date | null>(() => {
    if (!endTimestamp) return null;
    return new Date(endTimestamp * 1000);
  });

  useEffect(() => {
    if (!isRange || !endTimestamp) return;
    setEndDate(new Date(endTimestamp * 1000));
  }, [isRange, endTimestamp]);

  useEffect(() => {
    if (!timestamp) return;
    setStartDate(new Date(timestamp * 1000));
  }, [timestamp]);

  return (
    <div className={'flex w-full items-center justify-center'}>
      <DatePicker
        calendarClassName={
          'appflowy-date-picker-calendar select-none bg-bg-body h-full border-none rounded-none flex w-full items-center justify-center'
        }
        renderCustomHeader={(props: ReactDatePickerCustomHeaderProps) => {
          return (
            <div className={'flex w-full justify-between pb-1.5 pt-0'}>
              <div className={'flex-1 px-4 text-left text-sm font-medium text-text-title'}>
                {dayjs(props.date).format('MMMM YYYY')}
              </div>

              <div className={'flex items-center gap-[10px] pr-2'}>
                <IconButton size={'small'} onClick={props.decreaseMonth}>
                  <LeftSvg />
                </IconButton>
                <IconButton size={'small'} onClick={props.increaseMonth}>
                  <RightSvg />
                </IconButton>
              </div>
            </div>
          );
        }}
        selected={startDate}
        onChange={(dates) => {
          if (!dates) return;
          if (isRange && Array.isArray(dates)) {
            let start = dates[0] as Date;
            let end = dates[1] as Date;

            if (!end && start && startDate && endDate) {
              const currentTime = start.getTime();
              const startTimeStamp = startDate.getTime();
              const endTimeStamp = endDate.getTime();
              const isGreaterThanStart = currentTime > startTimeStamp;
              const isGreaterThanEnd = currentTime > endTimeStamp;
              const isLessThanStart = currentTime < startTimeStamp;
              const isLessThanEnd = currentTime < endTimeStamp;
              const isEqualsStart = currentTime === startTimeStamp;
              const isEqualsEnd = currentTime === endTimeStamp;

              if ((isGreaterThanStart && isLessThanEnd) || isGreaterThanEnd) {
                end = start;
                start = startDate;
              } else if (isEqualsStart || isEqualsEnd) {
                end = start;
              } else if (isLessThanStart) {
                end = endDate;
              }
            }

            setStartDate(start);
            setEndDate(end);
            if (!start || !end) return;
            handleChange({
              date: start.getTime() / 1000,
              endDate: end.getTime() / 1000,
            });
          } else {
            const date = dates as Date;

            setStartDate(date);
            handleChange({
              date: date.getTime() / 1000,
            });
          }
        }}
        startDate={isRange ? startDate : null}
        endDate={isRange ? endDate : null}
        selectsRange={isRange}
        inline
      />
    </div>
  );
}

export default CustomCalendar;
