import React, { useEffect } from 'react';
import Popover from '@mui/material/Popover';
import BlockSlashMenu from '$app/components/document/BlockSlash/BlockSlashMenu';
import { useBlockSlash } from '$app/components/document/BlockSlash/index.hooks';
import { Keyboard } from '$app/constants/document/keyboard';

function BlockSlash({ container }: { container: HTMLDivElement }) {
  const { blockId, open, onClose, anchorEl, searchText, hoverOption } = useBlockSlash();

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
