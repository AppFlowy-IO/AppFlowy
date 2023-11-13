import { Chip } from '@mui/material';
import { FC, MouseEventHandler, useCallback, useState } from 'react';
import { Sort } from '../../application';
import { SortMenu } from './SortMenu';

export interface SortsProps {
  sorts: Readonly<Sort>[];
}

export const Sorts: FC<SortsProps> = ({
  sorts,
}) => {
  const [ anchorEl, setAnchorEl ] = useState<HTMLElement | null>(null);
  const handleClick = useCallback<MouseEventHandler<HTMLElement>>((event) => {
    setAnchorEl(event.currentTarget);
  }, []);

  const label = sorts.length === 1
    ? (<div>1 sort</div>)
    : (<div>{sorts.length} sorts</div>);

  return (
    <>
      <Chip
        clickable
        variant="outlined"
        label={label}
        onClick={handleClick}
      />
      <SortMenu
        open={anchorEl !== null}
        anchorEl={anchorEl}
        onClose={() => setAnchorEl(null)}
      />
    </>
  );
};
