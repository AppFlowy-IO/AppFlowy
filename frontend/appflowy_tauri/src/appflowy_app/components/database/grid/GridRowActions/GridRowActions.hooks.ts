import React, { useCallback, useEffect, useRef, useState } from 'react';
import { useViewId } from '$app/hooks';
import { useGetPrevRowId } from '$app/components/database';
import { rowService } from '$app/components/database/application';
import { autoScrollOnEdge, ScrollDirection } from '$app/components/database/_shared/dnd/utils';

export function getCellsWithRowId(rowId: string, container: HTMLDivElement) {
  return Array.from(container.querySelectorAll(`[data-key^="row:${rowId}"]`));
}

const SELECTED_ROW_CSS_PROPERTY = 'bg-content-blue-50';

export function toggleProperty(
  container: HTMLDivElement,
  rowId: string,
  status: boolean,
  property = SELECTED_ROW_CSS_PROPERTY
) {
  const rowColumns = getCellsWithRowId(rowId, container);

  rowColumns.forEach((column, index) => {
    if (index === 0) return;
    if (status) {
      column.classList.add(property);
    } else {
      column.classList.remove(property);
    }
  });
}

function createVirtualDragElement(rowId: string, container: HTMLDivElement) {
  const cells = getCellsWithRowId(rowId, container);

  const cell = cells[0] as HTMLDivElement;

  if (!cell) return null;

  const rect = cell.getBoundingClientRect();

  const row = document.createElement('div');

  row.style.display = 'flex';
  row.style.position = 'absolute';
  row.style.top = `${rect.top}px`;
  row.style.left = `${rect.left + 64}px`;
  row.style.background = 'var(--content-blue-50)';
  cells.forEach((cell) => {
    const node = cell.cloneNode(true) as HTMLDivElement;

    if (!node.classList.contains('grid-cell')) return;

    node.style.top = '';
    node.style.position = '';
    node.style.left = '';
    node.style.width = (cell as HTMLDivElement).style.width;
    node.style.height = (cell as HTMLDivElement).style.height;
    node.className = 'flex items-center';
    row.appendChild(node);
  });

  document.body.appendChild(row);
  return row;
}

export function useDraggableGridRow(
  rowId: string,
  containerRef: React.RefObject<HTMLDivElement>,
  getScrollElement: () => HTMLDivElement | null
) {
  const [isDragging, setIsDragging] = useState(false);
  const dropRowIdRef = useRef<string | undefined>(undefined);
  const previewRef = useRef<HTMLDivElement | undefined>();
  const viewId = useViewId();
  const getPrevRowId = useGetPrevRowId();
  const onDragStart = useCallback(
    (e: React.DragEvent<HTMLButtonElement>) => {
      e.dataTransfer.effectAllowed = 'move';
      e.dataTransfer.dropEffect = 'move';
      const container = containerRef.current;

      if (container) {
        const row = createVirtualDragElement(rowId, container);

        if (row) {
          previewRef.current = row;
          e.dataTransfer.setDragImage(row, 0, 0);
        }
      }

      const scrollParent = getScrollElement();

      if (scrollParent) {
        autoScrollOnEdge({
          element: scrollParent,
          direction: ScrollDirection.Vertical,
        });
      }

      setIsDragging(true);
    },
    [containerRef, rowId, getScrollElement]
  );

  useEffect(() => {
    if (!isDragging) {
      if (previewRef.current) {
        const row = previewRef.current;

        previewRef.current = undefined;
        row?.remove();
      }

      return;
    }

    const container = containerRef.current;

    if (!container) {
      return;
    }

    const onDragOver = (e: DragEvent) => {
      e.preventDefault();
      e.stopPropagation();
      const target = e.target as HTMLElement;
      const cell = target.closest('[data-key]');
      const rowId = cell?.getAttribute('data-key')?.split(':')[1];

      const oldRowId = dropRowIdRef.current;

      if (oldRowId) {
        toggleProperty(container, oldRowId, false);
      }

      if (!rowId) return;

      const rowColumns = getCellsWithRowId(rowId, container);

      dropRowIdRef.current = rowId;
      if (!rowColumns.length) return;

      toggleProperty(container, rowId, true);
    };

    const onDragEnd = () => {
      const oldRowId = dropRowIdRef.current;

      if (oldRowId) {
        toggleProperty(container, oldRowId, false);
      }

      dropRowIdRef.current = undefined;
      setIsDragging(false);
    };

    const onDrop = async (e: DragEvent) => {
      e.preventDefault();
      e.stopPropagation();

      const dropRowId = dropRowIdRef.current;

      if (dropRowId) {
        void rowService.moveRow(viewId, rowId, dropRowId);
      }

      setIsDragging(false);
      container.removeEventListener('dragover', onDragOver);
      container.removeEventListener('dragend', onDragEnd);
      container.removeEventListener('drop', onDrop);
    };

    container.addEventListener('dragover', onDragOver);
    container.addEventListener('dragend', onDragEnd);
    container.addEventListener('drop', onDrop);
  }, [containerRef, getPrevRowId, isDragging, rowId, viewId]);

  return {
    isDragging,
    onDragStart,
  };
}

export function useGridTableHoverState(containerRef?: React.RefObject<HTMLDivElement>) {
  const [hoverRowId, setHoverRowId] = useState<string | undefined>(undefined);

  useEffect(() => {
    const container = containerRef?.current;

    if (!container) return;
    const onMouseMove = (e: MouseEvent) => {
      const target = e.target as HTMLElement;
      const cell = target.closest('[data-key]');

      if (!cell) {
        return;
      }

      const hoverRowId = cell.getAttribute('data-key')?.split(':')[1];

      setHoverRowId(hoverRowId);
    };

    const onMouseLeave = () => {
      setHoverRowId(undefined);
    };

    container.addEventListener('mousemove', onMouseMove);
    container.addEventListener('mouseleave', onMouseLeave);

    return () => {
      container.removeEventListener('mousemove', onMouseMove);
      container.removeEventListener('mouseleave', onMouseLeave);
    };
  }, [containerRef]);

  return {
    hoverRowId,
  };
}
