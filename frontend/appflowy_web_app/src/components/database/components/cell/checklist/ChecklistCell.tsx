import { parseChecklistData } from '@/application/database-yjs';
import { CellProps, ChecklistCell as ChecklistCellType } from '@/components/database/components/cell/cell.type';
import LinearProgressWithLabel from '@/components/_shared/progress/LinearProgressWithLabel';
import React, { useMemo } from 'react';

export function ChecklistCell({ cell, style, placeholder }: CellProps<ChecklistCellType>) {
  const data = useMemo(() => {
    return parseChecklistData(cell?.data ?? '');
  }, [cell?.data]);

  const options = data?.options;
  const selectedOptions = data?.selectedOptionIds;

  if (!data || !options || !selectedOptions)
    return placeholder ? (
      <div style={style} className={'text-text-placeholder'}>
        {placeholder}
      </div>
    ) : null;
  return (
    <div style={style} className={'w-full cursor-pointer'}>
      <LinearProgressWithLabel value={data?.percentage} count={options.length} selectedCount={selectedOptions.length} />
    </div>
  );
}
