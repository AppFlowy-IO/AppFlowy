import { FieldId } from '@/application/collab.type';
import { useFieldSelector, parseSelectOptionTypeOptions } from '@/application/database-yjs';
import { Tag } from '@/components/_shared/tag';
import { SelectOptionColorMap } from '@/components/database/components/cell/cell.const';
import { SelectCell } from '@/components/database/components/cell/cell.type';
import React, { useCallback, useMemo } from 'react';

export default function ({ cell, fieldId }: { cell?: SelectCell; rowId: string; fieldId: FieldId }) {
  const selectOptionIds = useMemo(() => cell?.data.split(','), [cell]);
  const { field } = useFieldSelector(fieldId);
  const typeOption = useMemo(() => {
    if (!field) return null;
    return parseSelectOptionTypeOptions(field);
  }, [field]);

  const renderSelectedOptions = useCallback(
    (selected: string[]) =>
      selected.map((id) => {
        const option = typeOption?.options?.find((option) => option.id === id);

        if (!option) return null;
        return <Tag key={option.id} color={SelectOptionColorMap[option.color]} label={option.name} />;
      }),
    [typeOption]
  );

  return (
    <div className={'flex h-full w-full cursor-pointer items-center gap-1 overflow-x-hidden'}>
      {selectOptionIds ? renderSelectedOptions(selectOptionIds) : null}
    </div>
  );
}
