import { useFieldsSelector, usePrimaryFieldId } from '@/application/database-yjs';
import { Property } from '@/components/database/components/property';
import React from 'react';

export function DatabaseRowProperties({ rowId }: { rowId: string }) {
  const primaryFieldId = usePrimaryFieldId();
  const fields = useFieldsSelector().filter((column) => column.fieldId !== primaryFieldId);

  return (
    <div className={'row-properties flex w-full flex-1 flex-col gap-4 px-16 py-2 max-md:px-4'}>
      {fields.map((field) => {
        return <Property fieldId={field.fieldId} rowId={rowId} key={field.fieldId} />;
      })}
    </div>
  );
}

export default DatabaseRowProperties;
