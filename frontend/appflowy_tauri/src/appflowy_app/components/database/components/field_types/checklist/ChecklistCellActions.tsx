import React from 'react';
import Popover, { PopoverProps } from '@mui/material/Popover';
import { LinearProgressWithLabel } from '$app/components/database/components/field_types/checklist/LinearProgressWithLabel';
import { Divider } from '@mui/material';
import { ChecklistCell as ChecklistCellType } from '$app/components/database/application';
import ChecklistItem from '$app/components/database/components/field_types/checklist/ChecklistItem';
import AddNewOption from '$app/components/database/components/field_types/checklist/AddNewOption';

function ChecklistCellActions({
  cell,
  ...props
}: PopoverProps & {
  cell: ChecklistCellType;
}) {
  const { fieldId, rowId } = cell;
  const { percentage, selectedOptions = [], options } = cell.data;

  return (
    <Popover {...props}>
      <LinearProgressWithLabel className={'m-4'} value={percentage || 0} />
      <div className={'p-1'}>
        {options?.map((option) => {
          return (
            <ChecklistItem
              fieldId={fieldId}
              rowId={rowId}
              key={option.id}
              option={option}
              checked={selectedOptions?.includes(option.id) || false}
            />
          );
        })}
      </div>

      <Divider />
      <AddNewOption fieldId={fieldId} rowId={rowId} />
    </Popover>
  );
}

export default ChecklistCellActions;
