import { CalendarEvent, useFieldsSelector } from '@/application/database-yjs';
import { RichTooltip } from '@/components/_shared/popover';
import EventPaper from '@/components/database/components/calendar/event/EventPaper';
import CardField from '@/components/database/components/field/CardField';
import React from 'react';
import { EventWrapperProps } from 'react-big-calendar';

export function Event({ event }: EventWrapperProps<CalendarEvent>) {
  const { id } = event;
  const [rowId] = id.split(':');
  const showFields = useFieldsSelector();

  // const navigateToRow = useNavigateToRow();
  const [open, setOpen] = React.useState(false);

  return (
    <div className={'px-1 py-0.5'}>
      <RichTooltip content={<EventPaper rowId={rowId} />} open={open} placement='right' onClose={() => setOpen(false)}>
        <div
          onClick={() => {
            if (window.innerWidth < 768) {
              // navigateToRow?.(rowId);
            } else {
              setOpen((prev) => !prev);
            }
          }}
          className={
            'flex min-h-[24px] cursor-pointer flex-col gap-2 rounded-md border border-line-border bg-bg-body p-2 text-xs text-xs shadow-sm hover:bg-fill-list-active hover:shadow'
          }
        >
          {showFields.map((field) => {
            return <CardField key={field.fieldId} index={0} rowId={rowId} fieldId={field.fieldId} />;
          })}
        </div>
      </RichTooltip>
    </div>
  );
}

export default Event;
