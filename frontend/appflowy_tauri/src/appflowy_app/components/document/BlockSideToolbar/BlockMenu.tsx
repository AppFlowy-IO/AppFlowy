import React, { useCallback, useState } from 'react';
import { List } from '@mui/material';
import { ContentCopy, Delete } from '@mui/icons-material';
import MenuItem from './MenuItem';
import { useBlockMenu } from '$app/components/document/BlockSideToolbar/BlockMenu.hooks';
import BlockMenuTurnInto from '$app/components/document/BlockSideToolbar/BlockMenuTurnInto';

function BlockMenu({ id, onClose }: { id: string; onClose: () => void }) {
  const { handleDelete, handleDuplicate } = useBlockMenu(id);

  const [turnIntoOptionHovered, setTurnIntoOptionHorvered] = useState<boolean>(false);
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
        // Prevent the block from being selected.
        e.preventDefault();
        e.stopPropagation();
      }}
    >
      {/** Delete option in the BlockMenu. */}
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
            setTurnIntoOptionHorvered(false);
          }
        }}
      />
      {/** Duplicate option in the BlockMenu. */}
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
            setTurnIntoOptionHorvered(false);
          }
        }}
      />
      {/** Turn Into option in the BlockMenu. */}
      <BlockMenuTurnInto
        onHovered={() => setTurnIntoOptionHorvered(true)}
        isHovered={turnIntoOptionHovered}
        onClose={onClose}
        id={id}
      />
    </List>
  );
}

export default BlockMenu;
