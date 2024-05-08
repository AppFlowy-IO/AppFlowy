import { parseSelectOptionTypeOptions, SelectOption, useFieldSelector } from '@/application/database-yjs';
import { Tag } from '@/components/_shared/tag';
import { SelectOptionColorMap } from '@/components/database/components/cell/cell.const';
import React, { useCallback, useMemo } from 'react';
import { ReactComponent as CheckIcon } from '$icons/16x/check.svg';

export function SelectOptionList({ fieldId, selectedIds }: { fieldId: string; selectedIds: string[] }) {
  const { field } = useFieldSelector(fieldId);
  const typeOption = useMemo(() => {
    if (!field) return null;
    return parseSelectOptionTypeOptions(field);
  }, [field]);

  const renderOption = useCallback(
    (option: SelectOption) => {
      const isSelected = selectedIds.includes(option.id);

      return (
        <div key={option.id} className={'flex items-center justify-between gap-2'}>
          <Tag label={option.name} color={SelectOptionColorMap[option.color]} />
          {isSelected && <CheckIcon />}
        </div>
      );
    },
    [selectedIds]
  );

  if (!field || !typeOption) return null;
  return <div className={'flex flex-col gap-2'}>{typeOption.options.map(renderOption)}</div>;
}
