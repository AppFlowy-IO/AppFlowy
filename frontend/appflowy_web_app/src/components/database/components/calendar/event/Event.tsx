import { CalendarEvent, useFieldsSelector } from '@/application/database-yjs';
import { RichTooltip } from '@/components/_shared/popover';
import EventPaper from '@/components/database/components/calendar/event/EventPaper';
import CardField from '@/components/database/components/field/CardField';
import React, { useMemo } from 'react';
import { EventWrapperProps } from 'react-big-calendar';

export function Event({ event }: EventWrapperProps<CalendarEvent>) {
  const { id } = event;
  const [rowId, fieldId] = id.split(':');
  const fields = useFieldsSelector();
  const showFields = useMemo(() => fields.filter((field) => field.fieldId !== fieldId), [fields, fieldId]);

  const [open, setOpen] = React.useState(false);

  return (
    <div className={'px-1 py-0.5'}>
      <RichTooltip content={<EventPaper rowId={rowId} />} open={open} placement='right' onClose={() => setOpen(false)}>
        <div
          onClick={() => setOpen((prev) => !prev)}
          className={
            'flex min-h-[24px] cursor-pointer flex-col gap-2 rounded-md border border-line-border bg-bg-body p-2 text-xs shadow-sm hover:bg-fill-list-active hover:shadow'
          }
        >
          {showFields.map((field) => {
            return (
              <div
                key={field.fieldId}
                style={{
                  fontSize: '0.85em',
                }}
                className={'overflow-x-hidden truncate'}
              >
                <CardField index={0} rowId={rowId} fieldId={field.fieldId} />
              </div>
            );
          })}
        </div>
      </RichTooltip>
    </div>
  );
}

export default Event;
