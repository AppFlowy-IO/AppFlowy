import { FieldId } from '@/application/collab.type';
import { parseChecklistData } from '@/application/database-yjs';
import { ChecklistCell } from '@/components/database/components/cell/cell.type';
import LinearProgressWithLabel from '@/components/_shared/progress/LinearProgressWithLabel';
import React, { useMemo } from 'react';

export default function ({ cell }: { cell?: ChecklistCell; rowId: string; fieldId: FieldId }) {
  const data = useMemo(() => {
    return parseChecklistData(cell?.data ?? '');
  }, [cell?.data]);

  const options = data?.options;
  const selectedOptions = data?.selectedOptionIds;

  if (!data || !options || !selectedOptions) return null;
  return (
    <div className={'cursor-pointer'}>
      <LinearProgressWithLabel value={data?.percentage} count={options.length} selectedCount={selectedOptions.length} />
    </div>
  );
}
