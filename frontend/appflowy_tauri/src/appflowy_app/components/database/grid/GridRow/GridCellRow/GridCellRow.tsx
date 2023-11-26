import { Virtualizer } from '@tanstack/react-virtual';
import { Portal } from '@mui/material';
import { DragEventHandler, FC, useCallback, useEffect, useMemo, useRef, useState } from 'react';
import { throttle } from '$app/utils/tool';
import { useViewId } from '$app/hooks';
import { useDatabaseVisibilityFields } from '../../../Database.hooks';
import { rowService, RowMeta } from '../../../application';
import {
  DragItem,
  DragType,
  DropPosition,
  VirtualizedList,
  useDraggable,
  useDroppable,
  ScrollDirection,
} from '../../../_shared';
import { GridCell } from '../../GridCell';
import { GridCellRowActions } from './GridCellRowActions';
import {
  useGridRowActionsDisplay,
  useGridRowContextMenu,
} from '$app/components/database/grid/GridRow/GridCellRow/GridCellRow.hooks';
import GridCellRowContextMenu from '$app/components/database/grid/GridRow/GridCellRow/GridCellRowContextMenu';
import { DEFAULT_FIELD_WIDTH } from '$app/components/database/grid/GridRow';

export interface GridCellRowProps {
  rowMeta: RowMeta;
  virtualizer: Virtualizer<HTMLDivElement, HTMLDivElement>;
  getPrevRowId: (id: string) => string | null;
}

export const GridCellRow: FC<GridCellRowProps> = ({ rowMeta, virtualizer, getPrevRowId }) => {
  const rowId = rowMeta.id;
  const viewId = useViewId();
  const ref = useRef<HTMLDivElement | null>(null);
  const { onMouseLeave, onMouseEnter, hover } = useGridRowActionsDisplay(rowId);
  const {
    isContextMenuOpen,
    closeContextMenu,
    openContextMenu,
    position: contextMenuPosition,
  } = useGridRowContextMenu();
  const fields = useDatabaseVisibilityFields();

  const [dropPosition, setDropPosition] = useState<DropPosition>(DropPosition.Before);
  const dragData = useMemo(
    () => ({
      rowMeta,
    }),
    [rowMeta]
  );

  const {
    isDragging,
    attributes: dragAttributes,
    listeners: dragListeners,
    setPreviewRef,
    previewRef,
  } = useDraggable({
    type: DragType.Row,
    data: dragData,
    scrollOnEdge: {
      direction: ScrollDirection.Vertical,
    },
  });

  const onDragOver = useMemo<DragEventHandler>(() => {
    return throttle((event) => {
      const element = previewRef.current;

      if (!element) {
        return;
      }

      const { top, bottom } = element.getBoundingClientRect();
      const middle = (top + bottom) / 2;

      setDropPosition(event.clientY < middle ? DropPosition.Before : DropPosition.After);
    }, 20);
  }, [previewRef]);

  const onDrop = useCallback(
    ({ data }: DragItem) => {
      void rowService.moveRow(viewId, (data.rowMeta as RowMeta).id, rowMeta.id);
    },
    [viewId, rowMeta.id]
  );

  const { isOver, listeners: dropListeners } = useDroppable({
    accept: DragType.Row,
    disabled: isDragging,
    onDragOver,
    onDrop,
  });

  useEffect(() => {
    const element = ref.current;

    if (!element) {
      return;
    }

    element.addEventListener('contextmenu', openContextMenu);
    return () => {
      element.removeEventListener('contextmenu', openContextMenu);
    };
  }, [openContextMenu]);

  return (
    <div
      ref={ref}
      className='relative -ml-16 flex grow pl-16'
      onMouseLeave={onMouseLeave}
      onMouseEnter={onMouseEnter}
      {...dropListeners}
    >
      <div
        ref={setPreviewRef}
        className={`relative flex grow border-b border-line-divider ${isDragging ? 'bg-blue-50' : ''}`}
      >
        <VirtualizedList
          className='flex'
          itemClassName='flex border-r border-line-divider'
          virtualizer={virtualizer}
          renderItem={(index) => {
            const field = fields[index];
            const icon = field.isPrimary ? rowMeta.icon : undefined;
            const documentId = field.isPrimary ? rowMeta.documentId : undefined;

            return <GridCell rowId={rowMeta.id} documentId={documentId} icon={icon} field={field} />;
          }}
        />
        <div className={`w-[${DEFAULT_FIELD_WIDTH}px]`} />
        {isOver && (
          <div
            className={`absolute left-0 right-0 z-10 h-0.5 bg-blue-500 ${
              dropPosition === DropPosition.Before ? 'top-[-1px]' : 'top-full'
            }`}
          />
        )}
      </div>
      <GridCellRowActions
        isHidden={!hover}
        className={'absolute left-2 top-[6px] z-10'}
        dragProps={{
          ...dragListeners,
          ...dragAttributes,
        }}
        rowId={rowMeta.id}
        getPrevRowId={getPrevRowId}
      />
      <Portal>
        {isContextMenuOpen && (
          <GridCellRowContextMenu
            open={isContextMenuOpen}
            onClose={closeContextMenu}
            anchorPosition={contextMenuPosition}
            rowId={rowId}
            getPrevRowId={getPrevRowId}
          />
        )}
      </Portal>
    </div>
  );
};
