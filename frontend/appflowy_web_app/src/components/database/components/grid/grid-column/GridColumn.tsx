import { YjsDatabaseKey } from '@/application/collab.type';
import { FieldType } from '@/application/database-yjs/database.type';
import { Column, useFieldSelector } from '@/application/database-yjs/selector';
import { FieldTypeIcon } from '@/components/database/components/field';
import { Tooltip } from '@mui/material';
import React, { useMemo } from 'react';
import { ReactComponent as AIIndicatorSvg } from '@/assets/ai_indicator.svg';

export function GridColumn({ column, index }: { column: Column; index: number }) {
  const { field } = useFieldSelector(column.fieldId);
  const name = field?.get(YjsDatabaseKey.name);
  const type = useMemo(() => {
    const type = field?.get(YjsDatabaseKey.type);

    if (!type) return FieldType.RichText;

    return parseInt(type) as FieldType;
  }, [field]);

  const isAIField = [FieldType.AISummaries, FieldType.AITranslations].includes(type);

  return (
    <Tooltip title={name} enterNextDelay={1000} placement={'right'}>
      <div
        style={{
          borderLeftWidth: index === 0 ? 0 : 1,
        }}
        className={
          'flex h-full w-full items-center gap-1 overflow-hidden whitespace-nowrap border-t border-b border-l border-line-divider px-2 font-medium hover:bg-fill-list-active'
        }
      >
        <div className={'w-5'}>
          <FieldTypeIcon type={type} className={'mr-1 h-5 w-5'} />
        </div>
        <div className={'flex-1'}>{name}</div>
        {isAIField && <AIIndicatorSvg className={'text-xl'} />}
      </div>
    </Tooltip>
  );
}

export default GridColumn;
