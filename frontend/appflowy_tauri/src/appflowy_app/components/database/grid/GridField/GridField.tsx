import { Button, Tooltip } from '@mui/material';
import { DragEventHandler, FC, useCallback, useMemo, useState } from 'react';
import { Database } from '$app/interfaces/database';
import { throttle } from '$app/utils/tool';
import { DragItem, DropPosition, DragType, useDraggable, useDroppable, ScrollDirection } from '../../_shared';
import * as service from '../../database_bd_svc';
import { useDatabase, useViewId } from '../../database.hooks';
import { FieldTypeSvg } from './FieldTypeSvg';
import { GridFieldMenu } from './GridFieldMenu';

export interface GridFieldProps {
  field: Database.Field;
}

export const GridField: FC<GridFieldProps> = ({ field }) => {
  const viewId = useViewId();
  const { fields } = useDatabase();
  const [ openMenu, setOpenMenu ] = useState(false);
  const [ openTooltip, setOpenTooltip ] = useState(false);
  const [ dropPosition, setDropPosition ] = useState<DropPosition>(DropPosition.Before);

  const handleClick = useCallback(() => {
    setOpenMenu(true);
  }, []);

  const handleMenuClose = useCallback(() => {
    setOpenMenu(false);
  }, []);

  const handleTooltipOpen = useCallback(() => {
    setOpenTooltip(true);
  }, []);

  const handleTooltipClose = useCallback(() => {
    setOpenTooltip(false);
  }, []);

  const draggingData = useMemo(() => ({
    field,
  }), [field]);

  const {
    isDragging,
    attributes,
    listeners,
    setPreviewRef,
    previewRef,
  } = useDraggable({
    type: DragType.Field,
    data: draggingData,
    scrollOnEdge: {
      direction: ScrollDirection.Horizontal,
    },
  });

  const onDragOver = useMemo<DragEventHandler>(() => {
    return throttle((event) => {
      const element = previewRef.current;

      if (!element) {
        return;
      }

      const { left, right } = element.getBoundingClientRect();
      const middle = (left + right) / 2;

      setDropPosition(event.clientX < middle ? DropPosition.Before : DropPosition.After);
    }, 20);
  }, [previewRef]);

  const onDrop = useCallback(({ data }: DragItem) => {
    const dragField = data.field as Database.Field;
    const fromIndex = fields.findIndex(item => item.id === dragField.id);
    const dropIndex = fields.findIndex(item => item.id === field.id);
    const toIndex = dropIndex + dropPosition + (fromIndex < dropIndex ? -1 : 0);

    if (fromIndex === toIndex) {
      return;
    }

    void service.moveField(viewId, dragField.id, fromIndex, toIndex);
  }, [viewId, field, fields, dropPosition]);

  const {
    isOver,
    listeners: dropListeners,
  } = useDroppable({
    accept: DragType.Field,
    disabled: isDragging,
    onDragOver,
    onDrop,
  });

  return (
    <>
      <Tooltip
        open={openTooltip && !isDragging}
        title={field.name}
        placement="right"
        enterDelay={1000}
        enterNextDelay={1000}
        onOpen={handleTooltipOpen}
        onClose={handleTooltipClose}
      >
        <Button
          ref={setPreviewRef}
          className="flex items-center px-2 w-full relative"
          disableRipple
          onClick={handleClick}
          {...attributes}
          {...listeners}
          {...dropListeners}
        >
          <FieldTypeSvg className="text-base mr-1" type={field.type} />
          <span className="flex-1 text-left text-xs truncate">
            {field.name}
          </span>
          {isOver && <div className={`absolute top-0 bottom-0 w-0.5 bg-blue-500 z-10 ${dropPosition === DropPosition.Before ? 'left-[-1px]' : 'left-full'}`} />}
        </Button>
      </Tooltip>
      {openMenu && (
        <GridFieldMenu
          field={field}
          open={openMenu}
          anchorEl={previewRef.current}
          onClose={handleMenuClose}
        />
      )}
    </>
  );
};
