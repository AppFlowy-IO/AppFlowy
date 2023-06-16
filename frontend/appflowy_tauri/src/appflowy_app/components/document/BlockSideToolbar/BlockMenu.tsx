import React, { useCallback, useState } from 'react';
import { List } from '@mui/material';
import { ContentCopy, Delete } from '@mui/icons-material';
import MenuItem from '../_shared/MenuItem';
import { useBlockMenu } from '$app/components/document/BlockSideToolbar/BlockMenu.hooks';
import BlockMenuTurnInto from '$app/components/document/BlockSideToolbar/BlockMenuTurnInto';

enum BlockMenuOption {
  Duplicate = 'Duplicate',
  Delete = 'Delete',
  TurnInto = 'TurnInto',
}

function BlockMenu({ id, onClose }: { id: string; onClose: () => void }) {
  const { handleDelete, handleDuplicate } = useBlockMenu(id);
  const [hovered, setHovered] = useState<BlockMenuOption | null>(null);
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
        onHover={() => {
          setHovered(BlockMenuOption.Delete);
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
        onHover={() => {
          setHovered(BlockMenuOption.Duplicate);
        }}
      />
      {/** Turn Into option in the BlockMenu. */}
      <BlockMenuTurnInto
        onHovered={() => setHovered(BlockMenuOption.TurnInto)}
        isHovered={hovered === BlockMenuOption.TurnInto}
        onClose={onClose}
        id={id}
      />
    </List>
  );
}

export default BlockMenu;
