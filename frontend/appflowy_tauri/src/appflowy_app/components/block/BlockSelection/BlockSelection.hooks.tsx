import { BlockEditor } from '@/appflowy_app/block_editor';
import { useEffect, useRef, useState, useCallback, useMemo } from 'react';

export function useBlockSelection({ container, blockEditor }: { container: HTMLDivElement; blockEditor: BlockEditor }) {
  const blockPositionManager = blockEditor.renderTree.blockPositionManager;

  const [isDragging, setDragging] = useState(false);
  const pointRef = useRef<number[]>([]);
  const startScrollTopRef = useRef<number>(0);

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

  const calcIntersectBlocks = useCallback(
    (clientX: number, clientY: number) => {
      if (!isDragging || !blockPositionManager) return;
      const [startX, startY] = pointRef.current;
      const endX = clientX + container.scrollLeft;
      const endY = clientY + container.scrollTop;

      setRect({
        startX,
        startY,
        endX,
        endY,
      });
      const selectedBlocks = blockPositionManager.getIntersectBlocks(
        Math.min(startX, endX),
        Math.min(startY, endY),
        Math.max(startX, endX),
        Math.max(startY, endY)
      );
      const ids = selectedBlocks.map((item) => item.id);
      blockEditor.renderTree.updateSelections(ids);
    },
    [isDragging]
  );

  const handleDraging = useCallback(
    (e: MouseEvent) => {
      if (!isDragging || !blockPositionManager) return;
      e.preventDefault();
      calcIntersectBlocks(e.clientX, e.clientY);

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
        blockEditor.renderTree.updateSelections([]);
        return;
      }
      if (!isDragging) return;
      e.preventDefault();
      calcIntersectBlocks(e.clientX, e.clientY);
      setDragging(false);
      setRect(null);
    },
    [isDragging]
  );

  useEffect(() => {
    window.addEventListener('mousedown', handleDragStart);
    window.addEventListener('mousemove', handleDraging);
    window.addEventListener('mouseup', handleDragEnd);

    return () => {
      window.removeEventListener('mousedown', handleDragStart);
      window.removeEventListener('mousemove', handleDraging);
      window.removeEventListener('mouseup', handleDragEnd);
    };
  }, [handleDragStart, handleDragEnd, handleDraging]);

  return {
    isDragging,
    style,
  };
}
