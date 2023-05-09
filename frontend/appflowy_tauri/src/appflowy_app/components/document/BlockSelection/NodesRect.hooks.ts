import { useCallback, useContext, useEffect, useMemo } from 'react';
import { DocumentControllerContext } from '$app/stores/effects/document/document_controller';
import { useAppSelector } from '$app/stores/store';
import { RegionGrid } from '$app/utils/region_grid';

export function useNodesRect(container: HTMLDivElement) {
  const controller = useContext(DocumentControllerContext);

  const data = useAppSelector((state) => {
    return state.document;
  });

  const regionGrid = useMemo(() => {
    if (!controller) return null;
    return new RegionGrid(300);
  }, [controller]);

  const updateNodeRect = useCallback(
    (node: Element) => {
      const { x, y, width, height } = node.getBoundingClientRect();
      const id = node.getAttribute('data-block-id');
      if (!id) return;
      const rect = {
        id,
        x: x + container.scrollLeft,
        y: y + container.scrollTop,
        width,
        height,
      };
      regionGrid?.updateBlock(rect);
    },
    [container.scrollLeft, container.scrollTop, regionGrid]
  );

  const updateViewPortNodesRect = useCallback(() => {
    const nodes = container.querySelectorAll('[data-block-id]');
    nodes.forEach(updateNodeRect);
  }, [container, updateNodeRect]);

  // update nodes rect when data changed
  useEffect(() => {
    updateViewPortNodesRect();
  }, [data, updateViewPortNodesRect]);

  // update nodes rect when scroll
  useEffect(() => {
    container.addEventListener('scroll', updateViewPortNodesRect);
    return () => {
      container.removeEventListener('scroll', updateViewPortNodesRect);
    };
  }, [container, updateViewPortNodesRect]);

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
