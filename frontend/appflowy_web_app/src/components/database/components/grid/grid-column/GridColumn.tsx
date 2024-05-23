import { YjsDatabaseKey } from '@/application/collab.type';
import { FieldType } from '@/application/database-yjs/database.type';
import { Column, useFieldSelector } from '@/application/database-yjs/selector';
import { FieldTypeIcon } from '@/components/database/components/field';
import React, { useMemo } from 'react';

export function GridColumn({ column, index }: { column: Column; index: number }) {
  const { field } = useFieldSelector(column.fieldId);
  const name = field?.get(YjsDatabaseKey.name);
  const type = useMemo(() => {
    const type = field?.get(YjsDatabaseKey.type);

    if (!type) return FieldType.RichText;

    return parseInt(type) as FieldType;
  }, [field]);

  return (
    <div
      style={{
        borderLeftWidth: index === 1 ? 0 : 1,
      }}
      className={
        'flex h-full w-full cursor-pointer items-center overflow-hidden whitespace-nowrap border-t border-b border-l border-line-divider px-1.5 text-xs font-medium hover:bg-fill-list-active'
      }
    >
      <div className={'w-5'}>
        <FieldTypeIcon type={type} className={'mr-1 h-4 w-4'} />
      </div>
      <div className={'flex-1'}>{name}</div>
    </div>
  );
}

export default GridColumn;
