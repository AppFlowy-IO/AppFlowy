import { IconButton } from '@mui/material';
import { FC, useCallback, useRef, useState } from 'react';
import { ReactComponent as DetailsSvg } from '$app/assets/details.svg';
import { Database } from '$app/interfaces/database';
import { FieldTypeSvg } from './FieldTypeSvg';
import { GridFieldMenu } from './GridFieldMenu';

export interface GridFieldProps {
  field: Database.Field;
}

export const GridField: FC<GridFieldProps> = ({ field }) => {
  const anchorEl = useRef<HTMLDivElement>(null);
  const [open, setOpen] = useState(false);

  const handleClick = useCallback(() => {
    setOpen(true);
  }, []);

  const handleClose = useCallback(() => {
    setOpen(false);
  }, []);

  return (
    <div
      ref={anchorEl}
      className="flex items-center p-3 h-full"
    >
      <div className="flex flex-1 items-center">
        <FieldTypeSvg type={field.type} className="text-base mr-2" />
        <span className="text-xs font-medium">
          {field.name}
        </span>
      </div>
      <IconButton size="small" onClick={handleClick}>
        <DetailsSvg />
      </IconButton>
      <GridFieldMenu
        field={field}
        open={open}
        anchorEl={anchorEl.current}
        onClose={handleClose}
      />
    </div>
  );
};