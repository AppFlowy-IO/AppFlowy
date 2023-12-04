import { useCallback, useEffect, useMemo, useState } from 'react';

export function useGridRowActionsDisplay(rowId: string, ref: React.RefObject<HTMLDivElement>) {
  const [hover, setHover] = useState(false);

  useEffect(() => {
    if (!ref.current) return;
    const el = ref.current;
    const onMouseLeave = () => {
      setHover(false);
    };

    const onMouseEnter = () => {
      setHover(true);
    };

    el.addEventListener('mouseenter', onMouseEnter);
    el.addEventListener('mouseleave', onMouseLeave);
    return () => {
      el.removeEventListener('mouseenter', onMouseEnter);
      el.removeEventListener('mouseleave', onMouseLeave);
    };
  }, [rowId, ref]);

  return {
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
