import React, { useCallback, useEffect, useMemo, useState } from 'react';
import GridRowMenu from './GridRowMenu';
import { toggleProperty } from './GridRowActions.hooks';

export function GridRowContextMenu({
  containerRef,
  hoverRowId,
  onOpenConfirm,
}: {
  hoverRowId?: string;
  onOpenConfirm: (onOk: () => Promise<void>, onCancel: () => void) => void;
  containerRef: React.MutableRefObject<HTMLDivElement | null>;
}) {
  const [position, setPosition] = useState<{ left: number; top: number } | undefined>();

  const [rowId, setRowId] = useState<string | undefined>();

  const isContextMenuOpen = useMemo(() => {
    return !!position;
  }, [position]);

  const closeContextMenu = useCallback(() => {
    setPosition(undefined);
    const container = containerRef.current;

    if (!container || !rowId) return;
    toggleProperty(container, rowId, false);
    // setRowId(undefined);
  }, [rowId, containerRef]);

  const openContextMenu = useCallback(
    (event: MouseEvent) => {
      event.preventDefault();
      event.stopPropagation();
      const container = containerRef.current;

      if (!container || !hoverRowId) return;
      toggleProperty(container, hoverRowId, true);
      setRowId(hoverRowId);
      setPosition({
        left: event.clientX,
        top: event.clientY,
      });
    },
    [containerRef, hoverRowId]
  );

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

  return rowId ? (
    <GridRowMenu
      onOpenConfirm={onOpenConfirm}
      open={isContextMenuOpen}
      onClose={closeContextMenu}
      anchorPosition={position}
      rowId={rowId}
    />
  ) : null;
}

export default GridRowContextMenu;
