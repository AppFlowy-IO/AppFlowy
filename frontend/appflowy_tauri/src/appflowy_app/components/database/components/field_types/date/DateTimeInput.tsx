import React, { useMemo } from 'react';
import { DateField, TimeField } from '@mui/x-date-pickers-pro';
import dayjs from 'dayjs';
import { Divider } from '@mui/material';

interface Props {
  onChange: (params: { date?: number; time?: string }) => void;
  date?: number;
  time?: string;
  timeFormat: string;
  dateFormat: string;
  includeTime?: boolean;
}

const sx = {
  '& .MuiOutlinedInput-notchedOutline': {
    border: 'none',
  },
  '& .MuiOutlinedInput-input': {
    padding: '0',
  },
};

function DateTimeInput({ includeTime, dateFormat, timeFormat, ...props }: Props) {
  const date = useMemo(() => {
    return dayjs.unix(props.date || dayjs().unix());
  }, [props.date]);

  const time = useMemo(() => {
    return dayjs(dayjs().format('YYYY/MM/DD ') + props.time);
  }, [props.time]);

  return (
    <div
      className={
        'flex transform items-center justify-between rounded-lg border border-line-divider px-1 py-2 transition-all'
      }
    >
      <DateField
        value={date}
        onChange={(date) => {
          if (!date) return;
          props.onChange({
            date: date.unix(),
          });
        }}
        inputProps={{
          className: 'text-[12px]',
        }}
        format={dateFormat}
        size={'small'}
        sx={sx}
        className={'flex-1 pl-2'}
      />

      {includeTime && (
        <>
          <Divider orientation={'vertical'} className={'mx-3'} flexItem />
          <TimeField
            value={time}
            inputProps={{
              className: 'text-[12px]',
            }}
            onChange={(time) => {
              if (!time) return;
              props.onChange({
                time: time.format(timeFormat),
              });
            }}
            format={timeFormat}
            size={'small'}
            sx={sx}
            className={'w-[70px] pl-1'}
          />
        </>
      )}
    </div>
  );
}

export default DateTimeInput;
