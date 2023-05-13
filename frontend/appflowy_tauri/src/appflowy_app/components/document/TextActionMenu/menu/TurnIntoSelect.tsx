import React, { useCallback } from 'react';
import { BlockType } from '$app/interfaces/document';
import TurnIntoPopover from '$app/components/document/_shared/TurnInto';
import Button from '@mui/material/Button';
import ArrowDropDown from '@mui/icons-material/ArrowDropDown';
import { Horizontal, Vertical } from '$app/components/document/_shared/Popover';
import MenuTooltip from './MenuTooltip';

function TurnIntoSelect({ id, selected }: { id: string; selected: BlockType }) {
  const [anchorEl, setAnchorEl] = React.useState<HTMLButtonElement | null>(null);

  const handleClick = useCallback((event: React.MouseEvent<HTMLButtonElement>) => {
    setAnchorEl(event.currentTarget);
  }, []);

  const handleClose = useCallback(() => {
    setAnchorEl(null);
  }, []);

  const open = Boolean(anchorEl);

  return (
    <>
      <MenuTooltip title='Turn into'>
        <Button size={'small'} variant='text' onClick={handleClick}>
          <div className='flex items-center text-main-accent'>
            <span>{selected}</span>
            <ArrowDropDown />
          </div>
        </Button>
      </MenuTooltip>
      <TurnIntoPopover
        id={id}
        open={open}
        onClose={handleClose}
        anchorEl={anchorEl}
        anchorOrigin={{
          vertical: Vertical.Center,
          horizontal: Horizontal.Center,
        }}
        transformOrigin={{
          vertical: Vertical.Center,
          horizontal: Horizontal.Center,
        }}
      />
    </>
  );
}

export default TurnIntoSelect;
