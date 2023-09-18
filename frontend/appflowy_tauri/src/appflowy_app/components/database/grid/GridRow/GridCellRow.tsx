import { Virtualizer } from '@tanstack/react-virtual';
import { IconButton } from '@mui/material';
import { FC, useCallback, useState } from 'react';
import { Database } from '$app/interfaces/database';
import { ReactComponent as DragSvg } from '$app/assets/drag.svg';
import { useDatabase, useViewId } from '../../database.hooks';
import * as service from '../../database_bd_svc';
import { GridCell } from '../GridCell';
import { DragItem, DragType, VirtualizedList, useDraggable, useDroppable } from '../_shared';
import { GridCellRowActions } from './GridCellRowActions';

export interface GridCellRowProps {
  row: Database.Row;
  virtualizer: Virtualizer<Element, Element>;
}

export const GridCellRow: FC<GridCellRowProps> = ({
  row,
  virtualizer,
}) => {
  const viewId = useViewId();
  const { fields } = useDatabase();
  const [ hover, setHover ] = useState(false);
  const {
    isDragging,
    attributes,
    listeners,
    setPreviewRef,
  } = useDraggable({
    type: DragType.Row,
    data: {
      row,
    },
  });

  const onDrop = useCallback(({ data }: DragItem) => {
    void service.moveRow(viewId, (data.row as Database.Row).id, row.id);
  }, [viewId, row.id]);

  const {
    isOver,
    listeners: dropListeners,
  } = useDroppable({
    accept: DragType.Row,
    disabled: isDragging,
    onDrop,
  });

  const handleMouseEnter = useCallback(() => {
    setHover(true);
  }, []);

  const handleMouseLeave = useCallback(() => {
    setHover(false);
  }, []);

  return (
    <div
      className="flex grow border-b border-line-divider"
      ref={setPreviewRef}
      onMouseEnter={handleMouseEnter}
      onMouseLeave={handleMouseLeave}
      {...dropListeners}
    >
      <GridCellRowActions
        className="ml-[-49px]"
        rowId={row.id}
      >
        <IconButton
          className="cursor-grab active:cursor-grabbing"
          {...attributes}
          {...listeners}
        >
          <DragSvg />
        </IconButton>
      </GridCellRowActions>
      <div className="flex grow relative">
        <VirtualizedList
          className="flex"
          itemClassName="flex border-r border-line-divider"
          virtualizer={virtualizer}
          renderItem={index => (
            <GridCell
              rowId={row.id}
              field={fields[index]}
            />
          )}
        />
        <div className="min-w-20 grow" />
        {isOver && <div className="absolute top-full left-0 right-0 h-0.5 bg-blue-50" />}
      </div>
    </div>
  );
};
