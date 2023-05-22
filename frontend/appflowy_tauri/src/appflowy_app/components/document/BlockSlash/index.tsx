import React from 'react';
import Popover from '@mui/material/Popover';
import BlockSlashMenu from '$app/components/document/BlockSlash/BlockSlashMenu';
import { useBlockSlash } from '$app/components/document/BlockSlash/index.hooks';

function BlockSlash() {
  const { blockId, open, onClose, anchorEl, searchText } = useBlockSlash();
  if (!blockId) return null;

  return (
    <Popover
      open={open}
      anchorEl={anchorEl}
      anchorOrigin={{
        vertical: 'bottom',
        horizontal: 'left',
      }}
      transformOrigin={{
        vertical: 'top',
        horizontal: 'left',
      }}
      disableAutoFocus
      onClose={onClose}
    >
      <BlockSlashMenu id={blockId} onClose={onClose} searchText={searchText} />
    </Popover>
  );
}

export default BlockSlash;
