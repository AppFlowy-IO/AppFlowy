import { parseChecklistData } from '@/application/database-yjs';
import { CellProps, ChecklistCell as CellType } from '@/application/database-yjs/cell.type';
import { ChecklistCell } from '@/components/database/components/cell/checklist';
import React, { useMemo } from 'react';
import { ReactComponent as CheckboxCheckSvg } from '$icons/16x/check_filled.svg';
import { ReactComponent as CheckboxUncheckSvg } from '$icons/16x/uncheck.svg';

export function ChecklistProperty(props: CellProps<CellType>) {
  const { cell } = props;
  const data = useMemo(() => {
    return parseChecklistData(cell?.data ?? '');
  }, [cell?.data]);

  const options = data?.options;
  const selectedOptions = data?.selectedOptionIds;

  return (
    <div className={'flex w-full flex-col gap-2 py-2'}>
      <ChecklistCell {...props} />
      {options?.map((option) => {
        const isSelected = selectedOptions?.includes(option.id);

        return (
          <div key={option.id} className={'flex items-center gap-2 text-xs font-medium'}>
            {isSelected ? <CheckboxCheckSvg className={'h-4 w-4'} /> : <CheckboxUncheckSvg className={'h-4 w-4'} />}
            <div>{option.name}</div>
          </div>
        );
      })}
    </div>
  );
}

export default ChecklistProperty;
