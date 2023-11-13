import { useGridUIStateDispatcher, useGridUIStateSelector } from '$app/components/database/proxy/grid/ui_state/actions';
import { CSSProperties, useCallback, useEffect, useMemo, useState } from 'react';

export function useGridRowActionsDisplay(rowId: string, ref: React.RefObject<HTMLDivElement>) {
  const { hoverRowId, isActivated } = useGridUIStateSelector();
  const hover = useMemo(() => {
    return isActivated && hoverRowId === rowId;
  }, [hoverRowId, rowId, isActivated]);

  const { setRowHover } = useGridUIStateDispatcher();
  const [actionsStyle, setActionsStyle] = useState<CSSProperties | undefined>();

  const onMouseEnter = useCallback(() => {
    setRowHover(rowId);
  }, [setRowHover, rowId]);

  const onMouseLeave = useCallback(() => {
    if (hover) {
      setRowHover(null);
    }
  }, [setRowHover, hover]);

  useEffect(() => {
    // Next frame to avoid layout thrashing
    requestAnimationFrame(() => {
      const element = ref.current;

      if (!hover || !element) {
        setActionsStyle(undefined);
        return;
      }

      const rect = element.getBoundingClientRect();

      setActionsStyle({
        position: 'absolute',
        top: rect.top + 6,
        left: rect.left - 50,
      });
    });
  }, [ref, hover]);

  return {
    actionsStyle,
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
