import { FieldId, YjsDatabaseKey } from '@/application/collab.type';
import { FieldType, useFieldSelector } from '@/application/database-yjs';
import { FieldTypeIcon } from '@/components/database/components/field/FieldTypeIcon';
import React from 'react';

export function FieldDisplay({ fieldId }: { fieldId: FieldId }) {
  const { field } = useFieldSelector(fieldId);
  const fieldType = Number(field?.get(YjsDatabaseKey.type)) as FieldType;

  if (!field) return null;

  return (
    <div className={'overflow flex w-full flex-nowrap items-center gap-1.5 truncate whitespace-nowrap font-medium '}>
      <FieldTypeIcon type={fieldType} />
      <span className={'text-xs'}>{field?.get(YjsDatabaseKey.name)}</span>
    </div>
  );
}

export default FieldDisplay;
