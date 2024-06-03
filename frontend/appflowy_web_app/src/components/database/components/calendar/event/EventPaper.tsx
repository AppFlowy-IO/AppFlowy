import { useFieldsSelector, usePrimaryFieldId } from '@/application/database-yjs';
import EventPaperTitle from '@/components/database/components/calendar/event/EventPaperTitle';
import OpenAction from '@/components/database/components/database-row/OpenAction';
import { Property } from '@/components/database/components/property';
import React from 'react';

function EventPaper({ rowId }: { rowId: string }) {
  const primaryFieldId = usePrimaryFieldId();

  const fields = useFieldsSelector().filter((column) => column.fieldId !== primaryFieldId);

  return (
    <div className={'max-h-[260px] w-[360px] overflow-y-auto'}>
      <div className={'flex h-fit w-full flex-col items-center justify-center py-2 px-3'}>
        <div className={'flex w-full items-center justify-end'}>
          <OpenAction rowId={rowId} />
        </div>
        <div className={'event-properties flex w-full flex-1 flex-col gap-4 overflow-y-auto py-2'}>
          {primaryFieldId && <EventPaperTitle rowId={rowId} fieldId={primaryFieldId} />}
          {fields.map((field) => {
            return <Property fieldId={field.fieldId} rowId={rowId} key={field.fieldId} />;
          })}
        </div>
      </div>
    </div>
  );
}

export default EventPaper;
