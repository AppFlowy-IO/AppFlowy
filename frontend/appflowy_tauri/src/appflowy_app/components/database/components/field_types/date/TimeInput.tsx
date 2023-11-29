import React, { useMemo } from 'react';
import dayjs, { Dayjs } from 'dayjs';
import DatePicker from 'react-datepicker';
import 'react-datepicker/dist/react-datepicker.css';
import { OutlinedInput } from '@mui/material';

function TimeInput({
  format,
  time,
  onChange,
  className,
}: {
  time: string;
  format: string;
  onChange: (time: string) => void;
  className?: string;
}) {
  const value = useMemo(() => {
    return dayjs(dayjs().format('YYYY/MM/DD ') + time);
  }, [time]);

  const handleChange = (newValue: Dayjs | null) => {
    if (newValue) {
      onChange(newValue.format(format));
    }
  };

  return (
    <DatePicker
      customInput={<OutlinedInput className={className} size={'small'} />}
      selected={value.toDate()}
      onChange={(date) => handleChange(dayjs(date))}
      showTimeSelectOnly
      popperContainer={() => null}
      dateFormat={format === 'HH:mm' ? 'HH:mm' : 'h:mm aa'}
    />
  );
}

export default TimeInput;
