import React from 'react';
import Popover from '@mui/material/Popover';
import BlockSlashMenu from '$app/components/document/BlockSlash/BlockSlashMenu';
import { useBlockSlash } from '$app/components/document/BlockSlash/index.hooks';

function BlockSlash({ container }: { container: HTMLDivElement }) {
  const { blockId, open, onClose, anchorPosition, searchText, hoverOption } = useBlockSlash();

  if (!blockId) return null;

  return (
    <Popover
      open={open}
      anchorReference={'anchorPosition'}
      anchorPosition={anchorPosition}
      transformOrigin={{
        vertical: 'top',
        horizontal: 'left',
      }}
      disableAutoFocus
      onClose={onClose}
    >
      <BlockSlashMenu
        container={container}
        hoverOption={hoverOption}
        id={blockId}
        onClose={onClose}
        searchText={searchText}
      />
    </Popover>
  );
}

export default BlockSlash;
