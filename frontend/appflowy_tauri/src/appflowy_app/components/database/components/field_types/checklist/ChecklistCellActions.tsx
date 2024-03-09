import React, { useState } from 'react';
import Popover, { PopoverProps } from '@mui/material/Popover';
import { Divider } from '@mui/material';
import { ChecklistCell as ChecklistCellType } from '$app/application/database';
import ChecklistItem from '$app/components/database/components/field_types/checklist/ChecklistItem';
import AddNewOption from '$app/components/database/components/field_types/checklist/AddNewOption';
import LinearProgressWithLabel from '$app/components/database/_shared/LinearProgressWithLabel';

function ChecklistCellActions({
  cell,
  maxHeight,
  maxWidth,
  ...props
}: PopoverProps & {
  cell: ChecklistCellType;
  maxWidth?: number;
  maxHeight?: number;
}) {
  const { fieldId, rowId } = cell;
  const { percentage, selectedOptions = [], options = [] } = cell.data;

  const [focusedId, setFocusedId] = useState<string | null>(null);

  return (
    <Popover {...props} disableRestoreFocus={true}>
      <div
        style={{
          maxHeight: maxHeight,
          maxWidth: maxWidth,
        }}
        className={'flex h-full w-full flex-col overflow-hidden'}
      >
        {options.length > 0 && (
          <>
            <div className={'p-2'}>
              <LinearProgressWithLabel
                value={percentage ?? 0}
                count={options.length}
                selectedCount={selectedOptions.length}
              />
            </div>
            <div className={'flex-1 overflow-y-auto overflow-x-hidden p-1'}>
              {options?.map((option) => {
                return (
                  <ChecklistItem
                    fieldId={fieldId}
                    rowId={rowId}
                    isSelected={focusedId === option.id}
                    key={option.id}
                    option={option}
                    onFocus={() => setFocusedId(option.id)}
                    onClose={() => props.onClose?.({}, 'escapeKeyDown')}
                    checked={selectedOptions?.includes(option.id) || false}
                  />
                );
              })}
            </div>

            <Divider />
          </>
        )}

        <AddNewOption
          onFocus={() => {
            setFocusedId(null);
          }}
          onClose={() => props.onClose?.({}, 'escapeKeyDown')}
          fieldId={fieldId}
          rowId={rowId}
        />
      </div>
    </Popover>
  );
}

export default ChecklistCellActions;
