import React, { useCallback } from 'react';
import TurnIntoPopover from '$app/components/document/_shared/TurnInto';
import Button from '@mui/material/Button';
import ArrowDropDown from '@mui/icons-material/ArrowDropDown';
import MenuTooltip from './MenuTooltip';
import { useSubscribeNode } from '$app/components/document/_shared/SubscribeNode.hooks';

function TurnIntoSelect({ id }: { id: string }) {
  const [anchorPosition, setAnchorPosition] = React.useState<{
    top: number;
    left: number;
  }>();

  const { node } = useSubscribeNode(id);
  const handleClick = useCallback((event: React.MouseEvent<HTMLButtonElement>) => {
    const rect = event.currentTarget.getBoundingClientRect();

    setAnchorPosition({
      top: rect.top + rect.height + 5,
      left: rect.left,
    });
  }, []);

  const handleClose = useCallback(() => {
    setAnchorPosition(undefined);
  }, []);

  const open = Boolean(anchorPosition);

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
        anchorReference={'anchorPosition'}
        anchorPosition={anchorPosition}
        transformOrigin={{
          vertical: 'top',
          horizontal: 'left',
        }}
      />
    </>
  );
}

export default TurnIntoSelect;
