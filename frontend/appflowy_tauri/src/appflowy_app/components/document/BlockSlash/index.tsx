import React, { useCallback } from 'react';
import Popover from '@mui/material/Popover';
import BlockSlashMenu from '$app/components/document/BlockSlash/BlockSlashMenu';
import { useBlockSlash } from '$app/components/document/BlockSlash/index.hooks';
import { SlashCommandOptionKey } from '$app/interfaces/document';
import DatabaseList from '$app/components/document/_shared/DatabaseList';
import { ViewLayoutPB } from '@/services/backend';

function BlockSlash({ container }: { container: HTMLDivElement }) {
  const {
    blockId,
    open,
    onClose,
    anchorPosition,
    searchText,
    hoverOption,
    onHoverOption,
    subMenuAnchorPosition,
    onCloseSubMenu,
  } = useBlockSlash();

  const renderSubMenu = useCallback(() => {
    if (!blockId) return null;
    switch (hoverOption?.key) {
      case SlashCommandOptionKey.GRID_REFERENCE:
        return <DatabaseList onClose={onClose} blockId={blockId} layout={ViewLayoutPB.Grid} searchText={searchText} />;
      default:
        return null;
    }
  }, [blockId, hoverOption?.key, onClose, searchText]);

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
        onHoverOption={onHoverOption}
      />
      <Popover
        transformOrigin={{
          vertical: 'top',
          horizontal: 'left',
        }}
        disableAutoFocus
        sx={{
          pointerEvents: 'none',
        }}
        PaperProps={{
          style: {
            pointerEvents: 'auto',
          },
        }}
        open={!!subMenuAnchorPosition}
        anchorReference={'anchorPosition'}
        anchorPosition={subMenuAnchorPosition}
        onClose={onCloseSubMenu}
      >
        {renderSubMenu()}
      </Popover>
    </Popover>
  );
}

export default BlockSlash;
