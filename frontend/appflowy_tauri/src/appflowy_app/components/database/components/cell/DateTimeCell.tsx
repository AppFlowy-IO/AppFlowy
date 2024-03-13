import React, { Suspense, useRef, useState, useMemo, useEffect } from 'react';
import { DateTimeCell as DateTimeCellType, DateTimeField } from '$app/application/database';
import DateTimeCellActions from '$app/components/database/components/field_types/date/DateTimeCellActions';
import usePopoverAutoPosition from '$app/components/_shared/popover/Popover.hooks';
import { PopoverOrigin } from '@mui/material/Popover/Popover';

interface Props {
  field: DateTimeField;
  cell: DateTimeCellType;
  placeholder?: string;
}

const initialAnchorOrigin: PopoverOrigin = {
  vertical: 'bottom',
  horizontal: 'left',
};

const initialTransformOrigin: PopoverOrigin = {
  vertical: 'top',
  horizontal: 'left',
};

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

  const { paperHeight, paperWidth, transformOrigin, anchorOrigin, isEntered, calculateAnchorSize } =
    usePopoverAutoPosition({
      initialPaperWidth: 248,
      initialPaperHeight: 500,
      anchorEl: ref.current,
      initialAnchorOrigin,
      initialTransformOrigin,
      open,
      marginThreshold: 34,
    });

  useEffect(() => {
    if (!open) return;

    const anchorEl = ref.current;

    const parent = anchorEl?.parentElement?.parentElement;

    if (!anchorEl || !parent) return;

    let timeout: NodeJS.Timeout;
    const handleObserve = () => {
      anchorEl.scrollIntoView({ block: 'nearest' });

      timeout = setTimeout(() => {
        calculateAnchorSize();
      }, 200);
    };

    const observer = new MutationObserver(handleObserve);

    observer.observe(parent, {
      childList: true,
      subtree: true,
    });
    return () => {
      observer.disconnect();
      clearTimeout(timeout);
    };
  }, [calculateAnchorSize, open]);

  return (
    <>
      <div
        ref={ref}
        className={`flex h-full min-h-[36px] w-full cursor-pointer items-center overflow-x-hidden truncate px-2 text-xs font-medium ${
          open ? 'bg-fill-list-active' : ''
        }`}
        onClick={handleClick}
      >
        {content}
      </div>
      <Suspense>
        {open && (
          <DateTimeCellActions
            field={field}
            maxWidth={paperWidth}
            maxHeight={paperHeight}
            anchorOrigin={anchorOrigin}
            transformOrigin={transformOrigin}
            onClose={handleClose}
            anchorEl={ref.current}
            cell={cell}
            open={open && isEntered}
          />
        )}
      </Suspense>
    </>
  );
}

export default DateTimeCell;
