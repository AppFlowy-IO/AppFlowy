import React, { Suspense, useRef, useState, useMemo } from 'react';
import { DateTimeCell as DateTimeCellType, DateTimeField } from '$app/components/database/application';
import DateTimeCellActions from '$app/components/database/components/field_types/date/DateTimeCellActions';

interface Props {
  field: DateTimeField;
  cell: DateTimeCellType;
  placeholder?: string;
}
function DateTimeCell({ field, cell, placeholder }: Props) {
  const isRange = cell.data.isRange;
  const includeTime = cell.data.includeTime;
  const [open, setOpen] = useState(false);
  const ref = useRef<HTMLDivElement>(null);

  const handleClose = () => {
    setOpen(false);
  };

  const handleClick = () => {
    setOpen(true);
  };

  const content = useMemo(() => {
    const { date, time, endDate, endTime } = cell.data;

    if (date) {
      return (
        <>
          {date}
          {includeTime && time ? ' ' + time : ''}
          {isRange && endDate ? ' - ' + endDate : ''}
          {isRange && includeTime && endTime ? ' ' + endTime : ''}
        </>
      );
    }

    return <div className={'text-sm text-text-placeholder'}>{placeholder}</div>;
  }, [cell, includeTime, isRange, placeholder]);

  return (
    <>
      <div ref={ref} className={'flex h-full w-full items-center px-2 text-xs font-medium'} onClick={handleClick}>
        {content}
      </div>
      <Suspense>
        {open && (
          <DateTimeCellActions field={field} onClose={handleClose} anchorEl={ref.current} cell={cell} open={open} />
        )}
      </Suspense>
    </>
  );
}

export default DateTimeCell;
