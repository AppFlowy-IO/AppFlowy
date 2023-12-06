import React, { useEffect } from 'react';
import GridRowMenu from './GridRowMenu';
import { useGridRowContextMenu } from './GridRowActions.hooks';

function GridRowContextMenu({
  containerRef,
  hoverRowId,
}: {
  hoverRowId?: string;
  containerRef: React.MutableRefObject<HTMLDivElement | null>;
}) {
  const {
    rowId: contextMenuRowId,
    setRowId: setContextMenuRowId,
    isContextMenuOpen,
    closeContextMenu,
    openContextMenu,
    position: contextMenuPosition,
  } = useGridRowContextMenu();

  useEffect(() => {
    const container = containerRef.current;

    if (!container) {
      return;
    }

    container.addEventListener('contextmenu', openContextMenu);
    return () => {
      container.removeEventListener('contextmenu', openContextMenu);
    };
  }, [containerRef, openContextMenu]);

  useEffect(() => {
    if (!hoverRowId) {
      return;
    }

    if (!isContextMenuOpen) {
      setContextMenuRowId(undefined);
      return;
    }

    setContextMenuRowId((prev) => {
      if (!prev) {
        return hoverRowId;
      }

      return prev;
    });
  }, [hoverRowId, isContextMenuOpen, setContextMenuRowId]);

  return isContextMenuOpen && contextMenuRowId ? (
    <GridRowMenu
      open={isContextMenuOpen}
      onClose={closeContextMenu}
      anchorPosition={contextMenuPosition}
      rowId={contextMenuRowId}
    />
  ) : null;
}

export default GridRowContextMenu;
