import React, { useCallback } from 'react';
import { List } from '@mui/material';
import { ContentCopy, Delete } from '@mui/icons-material';
import MenuItem from './MenuItem';
import { useBlockMenu } from '$app/components/document/BlockSideToolbar/BlockMenu.hooks';
import BlockMenuTurnInto from '$app/components/document/BlockSideToolbar/BlockMenuTurnInto';

function BlockMenu({ id, onClose }: { id: string; onClose: () => void }) {
  const { handleDelete, handleDuplicate } = useBlockMenu(id);

  const [turnIntoPup, setTurnIntoPup] = React.useState<boolean>(false);
  const handleClick = useCallback(
    async ({ operate }: { operate: () => Promise<void> }) => {
      await operate();
      onClose();
    },
    [onClose]
  );

  return (
    <List
      onMouseDown={(e) => {
        e.preventDefault();
        e.stopPropagation();
      }}
    >
      <MenuItem
        title='Delete'
        icon={<Delete />}
        onClick={() =>
          handleClick({
            operate: handleDelete,
          })
        }
        onHover={(isHovered) => {
          if (isHovered) {
            setTurnIntoPup(false);
          }
        }}
      />
      <MenuItem
        title='Duplicate'
        icon={<ContentCopy />}
        onClick={() =>
          handleClick({
            operate: handleDuplicate,
          })
        }
        onHover={(isHovered) => {
          if (isHovered) {
            setTurnIntoPup(false);
          }
        }}
      />
      <BlockMenuTurnInto onHovered={() => setTurnIntoPup(true)} isHovered={turnIntoPup} onClose={onClose} id={id} />
    </List>
  );
}

export default BlockMenu;
