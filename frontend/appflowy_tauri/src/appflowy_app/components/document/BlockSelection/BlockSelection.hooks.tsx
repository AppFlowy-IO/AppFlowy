import { useEffect, useRef, useState, useCallback, useMemo, useContext } from 'react';
import { useAppDispatch, useAppSelector } from '$app/stores/store';
import { documentActions } from '@/appflowy_app/stores/reducers/document/slice';
import { DocumentControllerContext } from '$app/stores/effects/document/document_controller';
import { debounce } from '$app/utils/tool';
import { RegionGrid } from '$app/utils/region_grid';

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
  const startPointRef = useRef<number[]>([]);

  const { getIntersectedBlockIds } = useNodesRect(container, isDragging);

  useEffect(() => {
    onDragging?.(isDragging);
  }, [isDragging, onDragging]);

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
  }, [container.scrollLeft, container.scrollTop, rect]);

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

  const handleDragStart = useCallback(
    (e: MouseEvent) => {
      if (isPointInBlock(e.target as HTMLElement)) {
        return;
      }
      e.preventDefault();
      setDragging(true);

      const startX = e.clientX + container.scrollLeft;
      const startY = e.clientY + container.scrollTop;
      startPointRef.current = [startX, startY];
      setRect({
        startX,
        startY,
        endX: startX,
        endY: startY,
      });
    },
    [container.scrollLeft, container.scrollTop, isPointInBlock]
  );

  const updateSelctionsByPoint = useCallback(
    (clientX: number, clientY: number) => {
      if (!isDragging) return;
      const [startX, startY] = startPointRef.current;
      const endX = clientX + container.scrollLeft;
      const endY = clientY + container.scrollTop;

      const newRect = {
        startX,
        startY,
        endX,
        endY,
      };
      const blockIds = getIntersectedBlockIds(newRect);
      disaptch(documentActions.updateSelections(blockIds));
      setRect(newRect);
    },
    [container.scrollLeft, container.scrollTop, disaptch, getIntersectedBlockIds, isDragging]
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
    [container, isDragging, updateSelctionsByPoint]
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
    [disaptch, isDragging, isPointInBlock, updateSelctionsByPoint]
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

function useNodesRect(container: HTMLDivElement, isDragging: boolean) {
  const controller = useContext(DocumentControllerContext);

  const data = useAppSelector((state) => {
    return {
      nodes: state.document.nodes,
      children: state.document.children,
    };
  });

  const regionGrid = useMemo(() => {
    if (!controller) return null;
    return new RegionGrid(300);
  }, [controller]);

  const debounceUpdateViewPortNodesRect = useMemo(() => {
    return debounce(() => {
      const nodes = container.querySelectorAll('[data-block-id]');
      Array.from(nodes).forEach((node) => {
        const id = node.getAttribute('data-block-id');
        if (!id) return;
        const { x, y, width, height } = node.getBoundingClientRect();
        const rect = {
          id,
          x: x + container.scrollLeft,
          y: y + container.scrollTop,
          width,
          height,
        };
        regionGrid?.updateBlock(rect);
      });
    }, 500);
  }, [container, regionGrid]);

  // update nodes rect when data changed
  useEffect(() => {
    if (isDragging) return;
    debounceUpdateViewPortNodesRect();
  }, [data, debounceUpdateViewPortNodesRect, isDragging]);

  // update nodes rect when scroll
  useEffect(() => {
    const handleScroll = () => {
      debounceUpdateViewPortNodesRect();
    };
    container.addEventListener('scroll', handleScroll);
    return () => {
      container.removeEventListener('scroll', handleScroll);
    };
  }, [container, debounceUpdateViewPortNodesRect]);

  const getIntersectedBlockIds = useCallback(
    (rect: { startX: number; startY: number; endX: number; endY: number }) => {
      if (!regionGrid) return [];
      const { startX, startY, endX, endY } = rect;
      const x = Math.min(startX, endX);
      const y = Math.min(startY, endY);
      const width = Math.abs(endX - startX);
      const height = Math.abs(endY - startY);
      return regionGrid
        .getIntersectingBlocks({
          x,
          y,
          width,
          height,
        })
        .map((block) => block.id);
    },
    [regionGrid]
  );

  return {
    getIntersectedBlockIds,
  };
}
