import React, { useCallback } from 'react';
import TurnIntoPopover from '$app/components/document/_shared/TurnInto';
import Button from '@mui/material/Button';
import ArrowDropDown from '@mui/icons-material/ArrowDropDown';
import MenuTooltip from './MenuTooltip';
import { useSubscribeNode } from '$app/components/document/_shared/SubscribeNode.hooks';

function TurnIntoSelect({ id }: { id: string }) {
  const [anchorEl, setAnchorEl] = React.useState<HTMLButtonElement | null>(null);

  const { node } = useSubscribeNode(id);
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
            <span>{node.type}</span>
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
          vertical: 'center',
          horizontal: 'center',
        }}
        transformOrigin={{
          vertical: 'center',
          horizontal: 'center',
        }}
      />
    </>
  );
}

export default TurnIntoSelect;
