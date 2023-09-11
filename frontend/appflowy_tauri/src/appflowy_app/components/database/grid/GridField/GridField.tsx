import { Button } from '@mui/material';
import { FC, useCallback, useRef, useState } from 'react';
import { Database } from '$app/interfaces/database';
import { FieldTypeSvg } from './FieldTypeSvg';
import { GridFieldMenu } from './GridFieldMenu';

export interface GridFieldProps {
  field: Database.Field;
}

export const GridField: FC<GridFieldProps> = ({ field }) => {
  const anchorEl = useRef<HTMLButtonElement>(null);
  const [open, setOpen] = useState(false);

  const handleClick = useCallback(() => {
    setOpen(true);
  }, []);

  const handleClose = useCallback(() => {
    setOpen(false);
  }, []);

  return (
    <>
      <Button
        ref={anchorEl}
        className="flex items-center px-2 w-full"
        onClick={handleClick}
      >
        <FieldTypeSvg className="text-base mr-1" type={field.type} />
        <span className="flex-1 text-left text-xs truncate">
          {field.name}
        </span>
      </Button>
      {open && (
        <GridFieldMenu
          field={field}
          open={open}
          anchorEl={anchorEl.current}
          onClose={handleClose}
        />
      )}
    </>
  );
};
