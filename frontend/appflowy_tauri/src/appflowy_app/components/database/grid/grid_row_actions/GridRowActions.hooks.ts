import React, { useCallback, useEffect, useRef, useState } from 'react';
import { useViewId } from '$app/hooks';
import { rowService } from '$app/application/database';
import { autoScrollOnEdge, ScrollDirection } from '$app/components/database/_shared/dnd/utils';
import { useSortsCount } from '$app/components/database';
import { deleteAllSorts } from '$app/application/database/sort/sort_service';

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

  const row = document.createElement('div');

  row.style.display = 'flex';
  row.style.position = 'absolute';
  row.style.top = cell.style.top;
  const left = Number(cell.style.left.split('px')[0]) + 64;

  row.style.left = `${left}px`;
  row.style.background = 'var(--content-blue-50)';
  cells.forEach((cell) => {
    const node = cell.cloneNode(true) as HTMLDivElement;

    if (!node.classList.contains('grid-cell')) return;

    node.style.top = '';
    node.style.position = '';
    node.style.left = '';
    node.style.width = (cell as HTMLDivElement).style.width;
    node.style.height = (cell as HTMLDivElement).style.height;
    node.className = 'flex items-center border-r border-b border-divider-line opacity-50';
    row.appendChild(node);
  });

  cell.parentElement?.appendChild(row);
  return row;
}

export function useDraggableGridRow(
  rowId: string,
  containerRef: React.RefObject<HTMLDivElement>,
  getScrollElement: () => HTMLDivElement | null,
  onOpenConfirm: (onOk: () => Promise<void>, onCancel: () => void) => void
) {
  const viewId = useViewId();
  const sortsCount = useSortsCount();

  const [isDragging, setIsDragging] = useState(false);
  const dropRowIdRef = useRef<string | undefined>(undefined);
  const previewRef = useRef<HTMLDivElement | undefined>();

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
          edgeGap: 20,
        });
      }

      setIsDragging(true);
    },
    [containerRef, rowId, getScrollElement]
  );

  const moveRowTo = useCallback(
    async (toRowId: string) => {
      return rowService.moveRow(viewId, rowId, toRowId);
    },
    [viewId, rowId]
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

      toggleProperty(container, rowId, false);
      if (dropRowId) {
        if (sortsCount > 0) {
          onOpenConfirm(
            async () => {
              await deleteAllSorts(viewId);
              await moveRowTo(dropRowId);
            },
            () => {
              void moveRowTo(dropRowId);
            }
          );
        } else {
          void moveRowTo(dropRowId);
        }

        toggleProperty(container, dropRowId, false);
      }

      setIsDragging(false);
      container.removeEventListener('dragover', onDragOver);
      container.removeEventListener('dragend', onDragEnd);
      container.removeEventListener('drop', onDrop);
    };

    container.addEventListener('dragover', onDragOver);
    container.addEventListener('dragend', onDragEnd);
    container.addEventListener('drop', onDrop);
  }, [isDragging, containerRef, moveRowTo, onOpenConfirm, rowId, sortsCount, viewId]);

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
