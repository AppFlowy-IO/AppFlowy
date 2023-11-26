import { useGridUIStateDispatcher, useGridUIStateSelector } from '$app/components/database/proxy/grid/ui_state/actions';
import { useCallback, useMemo, useState } from 'react';

export function useGridRowActionsDisplay(rowId: string) {
  const { hoverRowId, isActivated } = useGridUIStateSelector();
  const hover = useMemo(() => {
    return isActivated && hoverRowId === rowId;
  }, [hoverRowId, rowId, isActivated]);

  const { setRowHover } = useGridUIStateDispatcher();

  const onMouseEnter = useCallback(() => {
    setRowHover(rowId);
  }, [setRowHover, rowId]);

  const onMouseLeave = useCallback(() => {
    if (hover) {
      setRowHover(null);
    }
  }, [setRowHover, hover]);

  return {
    onMouseEnter,
    onMouseLeave,
    hover,
  };
}

export const useGridRowContextMenu = () => {
  const [position, setPosition] = useState<{ left: number; top: number } | undefined>();

  const isContextMenuOpen = useMemo(() => {
    return !!position;
  }, [position]);

  const closeContextMenu = useCallback(() => {
    setPosition(undefined);
  }, []);

  const openContextMenu = useCallback((event: MouseEvent) => {
    event.preventDefault();
    event.stopPropagation();

    setPosition({
      left: event.clientX,
      top: event.clientY,
    });
  }, []);

  return {
    isContextMenuOpen,
    closeContextMenu,
    openContextMenu,
    position,
  };
};
