import React, { Suspense, useRef, useState, lazy, useMemo } from 'react';
import { DateTimeCell as DateTimeCellType, DateTimeField } from '$app/components/database/application';

const DateTimeCellActions = lazy(
  () => import('$app/components/database/components/field_types/date/DateTimeCellActions')
);

interface Props {
  field: DateTimeField;
  cell?: DateTimeCellType;
  placeholder?: string;
}
function DateTimeCell({ field, cell, placeholder }: Props) {
  const isRange = cell?.data.isRange;
  const [open, setOpen] = useState(false);
  const ref = useRef<HTMLDivElement>(null);

  const handleClose = () => {
    setOpen(false);
  };

  const handleClick = () => {
    setOpen(true);
  };

  const content = useMemo(() => {
    if (cell && cell?.data.date) {
      return (
        <>
          {cell?.data.date}
          {isRange && cell?.data.endDate ? ' - ' + cell?.data.endDate : ''}
        </>
      );
    }

    return <div className={'text-sm text-text-placeholder'}>{placeholder}</div>;
  }, [cell, isRange, placeholder]);

  return (
    <>
      <div ref={ref} className={'flex h-full w-full items-center px-2'} onClick={handleClick}>
        {content}
      </div>
      <Suspense>
        {cell && open && (
          <DateTimeCellActions field={field} onClose={handleClose} anchorEl={ref.current} cell={cell} open={open} />
        )}
      </Suspense>
    </>
  );
}

export default DateTimeCell;
