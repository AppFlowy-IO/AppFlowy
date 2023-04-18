import { useEffect, useRef, useState, useCallback, useMemo } from 'react';
import { useAppDispatch } from '$app/stores/store';
import { documentActions } from '@/appflowy_app/stores/reducers/document/slice';

export function useBlockSelection({
  container,
  onDragging,
}: {
  container: HTMLDivElement;
  onDragging?: (_isDragging: boolean) => void;
}) {
  const ref = useRef<HTMLDivElement | null>(null);
  const disaptch = useAppDispatch();

  const [isDragging, setDragging] = useState(false);
  const pointRef = useRef<number[]>([]);
  const startScrollTopRef = useRef<number>(0);

  useEffect(() => {
    onDragging?.(isDragging);
  }, [isDragging]);

  const [rect, setRect] = useState<{
    startX: number;
    startY: number;
    endX: number;
    endY: number;
  } | null>(null);

  const style = useMemo(() => {
    if (!rect) return;
    const { startX, endX, startY, endY } = rect;
    const x = Math.min(startX, endX);
    const y = Math.min(startY, endY);
    const width = Math.abs(endX - startX);
    const height = Math.abs(endY - startY);
    return {
      left: x - container.scrollLeft + 'px',
      top: y - container.scrollTop + 'px',
      width: width + 'px',
      height: height + 'px',
    };
  }, [rect]);

  const isPointInBlock = useCallback((target: HTMLElement | null) => {
    let node = target;
    while (node) {
      if (node.getAttribute('data-block-id')) {
        return true;
      }
      node = node.parentElement;
    }
    return false;
  }, []);

  const handleDragStart = useCallback((e: MouseEvent) => {
    if (isPointInBlock(e.target as HTMLElement)) {
      return;
    }
    e.preventDefault();
    setDragging(true);

    const startX = e.clientX + container.scrollLeft;
    const startY = e.clientY + container.scrollTop;
    pointRef.current = [startX, startY];
    startScrollTopRef.current = container.scrollTop;
    setRect({
      startX,
      startY,
      endX: startX,
      endY: startY,
    });
  }, []);

  const updateSelctionsByPoint = useCallback(
    (clientX: number, clientY: number) => {
      if (!isDragging) return;
      const [startX, startY] = pointRef.current;
      const endX = clientX + container.scrollLeft;
      const endY = clientY + container.scrollTop;

      setRect({
        startX,
        startY,
        endX,
        endY,
      });
      disaptch(
        documentActions.setSelectionByRect({
          startX: Math.min(startX, endX),
          startY: Math.min(startY, endY),
          endX: Math.max(startX, endX),
          endY: Math.max(startY, endY),
        })
      );
    },
    [isDragging]
  );

  const handleDraging = useCallback(
    (e: MouseEvent) => {
      if (!isDragging) return;
      e.preventDefault();
      e.stopPropagation();
      updateSelctionsByPoint(e.clientX, e.clientY);

      const { top, bottom } = container.getBoundingClientRect();
      if (e.clientY >= bottom) {
        const delta = e.clientY - bottom;
        container.scrollBy(0, delta);
      } else if (e.clientY <= top) {
        const delta = e.clientY - top;
        container.scrollBy(0, delta);
      }
    },
    [isDragging]
  );

  const handleDragEnd = useCallback(
    (e: MouseEvent) => {
      if (isPointInBlock(e.target as HTMLElement) && !isDragging) {
        disaptch(documentActions.updateSelections([]));
        return;
      }
      if (!isDragging) return;
      e.preventDefault();
      updateSelctionsByPoint(e.clientX, e.clientY);
      setDragging(false);
      setRect(null);
    },
    [isDragging]
  );

  useEffect(() => {
    if (!ref.current) return;
    document.addEventListener('mousedown', handleDragStart);
    document.addEventListener('mousemove', handleDraging);
    document.addEventListener('mouseup', handleDragEnd);

    return () => {
      document.removeEventListener('mousedown', handleDragStart);
      document.removeEventListener('mousemove', handleDraging);
      document.removeEventListener('mouseup', handleDragEnd);
    };
  }, [handleDragStart, handleDragEnd, handleDraging]);

  return {
    isDragging,
    style,
    ref,
  };
}
