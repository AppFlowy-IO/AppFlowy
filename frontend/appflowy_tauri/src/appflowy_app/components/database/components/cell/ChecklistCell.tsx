import React, { useState, Suspense, useMemo } from 'react';
import { ChecklistCell as ChecklistCellType, ChecklistField } from '$app/application/database';
import ChecklistCellActions from '$app/components/database/components/field_types/checklist/ChecklistCellActions';
import LinearProgressWithLabel from '$app/components/database/_shared/LinearProgressWithLabel';
import { PopoverOrigin } from '@mui/material/Popover/Popover';
import usePopoverAutoPosition from '$app/components/_shared/popover/Popover.hooks';

interface Props {
  field: ChecklistField;
  cell: ChecklistCellType;
  placeholder?: string;
}

const initialAnchorOrigin: PopoverOrigin = {
  vertical: 'bottom',
  horizontal: 'left',
};

const initialTransformOrigin: PopoverOrigin = {
  vertical: 'top',
  horizontal: 'left',
};

function ChecklistCell({ cell, placeholder }: Props) {
  const value = cell?.data.percentage ?? 0;
  const options = useMemo(() => cell?.data.options ?? [], [cell?.data.options]);
  const selectedOptions = useMemo(() => cell?.data.selectedOptions ?? [], [cell?.data.selectedOptions]);
  const [anchorEl, setAnchorEl] = useState<HTMLDivElement | undefined>(undefined);
  const open = Boolean(anchorEl);
  const handleClick = (e: React.MouseEvent<HTMLDivElement>) => {
    setAnchorEl(e.currentTarget);
  };

  const handleClose = () => {
    setAnchorEl(undefined);
  };

  const { paperHeight, paperWidth, transformOrigin, anchorOrigin, isEntered } = usePopoverAutoPosition({
    initialPaperWidth: 369,
    initialPaperHeight: 300,
    anchorEl,
    initialAnchorOrigin,
    initialTransformOrigin,
    open,
  });

  return (
    <>
      <div className='flex w-full cursor-pointer items-center px-2' onClick={handleClick}>
        {options.length > 0 ? (
          <LinearProgressWithLabel value={value} count={options.length} selectedCount={selectedOptions.length} />
        ) : (
          <div className={'text-sm text-text-placeholder'}>{placeholder}</div>
        )}
      </div>
      <Suspense>
        {open && (
          <ChecklistCellActions
            transformOrigin={transformOrigin}
            anchorOrigin={anchorOrigin}
            maxHeight={paperHeight}
            maxWidth={paperWidth}
            open={open && isEntered}
            anchorEl={anchorEl}
            onClose={handleClose}
            cell={cell}
          />
        )}
      </Suspense>
    </>
  );
}

export default ChecklistCell;
