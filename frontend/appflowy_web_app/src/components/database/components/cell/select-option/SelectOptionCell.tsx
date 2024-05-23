import { useFieldSelector, parseSelectOptionTypeOptions } from '@/application/database-yjs';
import { Tag } from '@/components/_shared/tag';
import { SelectOptionColorMap } from '@/components/database/components/cell/cell.const';
import { CellProps, SelectOptionCell as SelectOptionCellType } from '@/components/database/components/cell/cell.type';
import React, { useCallback, useMemo } from 'react';

export function SelectOptionCell({ cell, fieldId, style, placeholder }: CellProps<SelectOptionCellType>) {
  const selectOptionIds = useMemo(() => (!cell?.data ? [] : cell?.data.split(',')), [cell]);
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
        return <Tag key={option.id} size={'small'} color={SelectOptionColorMap[option.color]} label={option.name} />;
      }),
    [typeOption]
  );

  if (!typeOption || !selectOptionIds?.length)
    return placeholder ? (
      <div style={style} className={'text-text-placeholder'}>
        {placeholder}
      </div>
    ) : null;

  return (
    <div style={style} className={'flex h-full w-full cursor-pointer items-center gap-1 overflow-x-hidden'}>
      {renderSelectedOptions(selectOptionIds)}
    </div>
  );
}
