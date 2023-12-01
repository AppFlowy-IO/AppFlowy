import React, { useState, Suspense, useMemo } from 'react';
import { ChecklistCell as ChecklistCellType, ChecklistField } from '$app/components/database/application';
import Typography from '@mui/material/Typography';
import ChecklistCellActions from '$app/components/database/components/field_types/checklist/ChecklistCellActions';

interface Props {
  field: ChecklistField;
  cell: ChecklistCellType;
}

function ChecklistCell({ cell }: Props) {
  const value = cell?.data.percentage ?? 0;

  const [anchorEl, setAnchorEl] = useState<HTMLDivElement | undefined>(undefined);
  const open = Boolean(anchorEl);
  const handleClick = (e: React.MouseEvent<HTMLDivElement>) => {
    setAnchorEl(e.currentTarget);
  };

  const handleClose = () => {
    setAnchorEl(undefined);
  };

  const result = useMemo(() => `${Math.round(value * 100)}%`, [value]);

  return (
    <>
      <div className='flex w-full cursor-pointer items-center px-2' onClick={handleClick}>
        <Typography variant='body2' color='text.secondary'>
          {result}
        </Typography>
      </div>
      <Suspense>
        {open && (
          <ChecklistCellActions
            transformOrigin={{
              vertical: 'top',
              horizontal: 'left',
            }}
            anchorOrigin={{
              vertical: 'bottom',
              horizontal: 'left',
            }}
            open={open}
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
