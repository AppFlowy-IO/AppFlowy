import { Button, Tooltip } from '@mui/material';
import { DragEventHandler, FC, useCallback, useEffect, useMemo, useState } from 'react';
import { throttle } from '$app/utils/tool';
import { useViewId } from '$app/hooks';
import { DragItem, DropPosition, DragType, useDraggable, useDroppable, ScrollDirection } from '../../_shared';
import { fieldService, Field } from '../../application';
import { useDatabase } from '../../Database.hooks';
import { Property } from '$app/components/database/components/property';
import GridResizer from '$app/components/database/grid/GridField/GridResizer';
import { DEFAULT_FIELD_WIDTH } from '$app/components/database/grid/GridRow';
import GridFieldMenu from '$app/components/database/grid/GridField/GridFieldMenu';

export interface GridFieldProps {
  field: Field;
  menuOpened?: boolean;
  onOpenMenu?: (id: string) => void;
  onCloseMenu?: (id: string) => void;
}

export const GridField: FC<GridFieldProps> = ({ menuOpened, onOpenMenu, onCloseMenu, field }) => {
  const viewId = useViewId();
  const { fields } = useDatabase();
  const [openTooltip, setOpenTooltip] = useState(false);
  const [propertyMenuOpened, setPropertyMenuOpened] = useState(false);
  const [dropPosition, setDropPosition] = useState<DropPosition>(DropPosition.Before);
  const [fieldWidth, setFieldWidth] = useState(field.width || DEFAULT_FIELD_WIDTH);

  const handleTooltipOpen = useCallback(() => {
    setOpenTooltip(true);
  }, []);

  const handleTooltipClose = useCallback(() => {
    setOpenTooltip(false);
  }, []);

  const draggingData = useMemo(
    () => ({
      field,
    }),
    [field]
  );

  const { isDragging, attributes, listeners, setPreviewRef, previewRef } = useDraggable({
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

  const onDrop = useCallback(
    ({ data }: DragItem) => {
      const dragField = data.field as Field;
      const fromIndex = fields.findIndex((item) => item.id === dragField.id);
      const dropIndex = fields.findIndex((item) => item.id === field.id);
      const toIndex = dropIndex + dropPosition + (fromIndex < dropIndex ? -1 : 0);

      if (fromIndex === toIndex) {
        return;
      }

      void fieldService.moveField(viewId, dragField.id, fromIndex, toIndex);
    },
    [viewId, field, fields, dropPosition]
  );

  const { isOver, listeners: dropListeners } = useDroppable({
    accept: DragType.Field,
    disabled: isDragging,
    onDragOver,
    onDrop,
  });

  const [menuAnchorPosition, setMenuAnchorPosition] = useState<
    | {
        top: number;
        left: number;
      }
    | undefined
  >(undefined);

  const open = Boolean(menuAnchorPosition) && menuOpened;

  const handleClick = useCallback(() => {
    onOpenMenu?.(field.id);
  }, [onOpenMenu, field.id]);

  const handleMenuClose = useCallback(() => {
    onCloseMenu?.(field.id);
  }, [onCloseMenu, field.id]);

  useEffect(() => {
    if (!menuOpened) {
      setMenuAnchorPosition(undefined);
      return;
    }

    const rect = previewRef.current?.getBoundingClientRect();

    if (rect) {
      setMenuAnchorPosition({
        top: rect.top + rect.height,
        left: rect.left,
      });
    } else {
      setMenuAnchorPosition(undefined);
    }
  }, [menuOpened, previewRef]);

  const handlePropertyMenuOpen = useCallback(() => {
    setPropertyMenuOpened(true);
  }, []);

  const handlePropertyMenuClose = useCallback(() => {
    setPropertyMenuOpened(false);
  }, []);

  return (
    <div
      className={'flex border-r border-line-divider bg-bg-body'}
      style={{
        width: fieldWidth,
      }}
    >
      <Tooltip
        open={openTooltip && !isDragging}
        title={field.name}
        placement='right'
        enterDelay={1000}
        enterNextDelay={1000}
        onOpen={handleTooltipOpen}
        onClose={handleTooltipClose}
      >
        <Button
          color={'inherit'}
          ref={setPreviewRef}
          className='relative flex w-full items-center px-2'
          disableRipple
          onContextMenu={(event) => {
            event.stopPropagation();
            event.preventDefault();
            handleClick();
          }}
          onClick={handleClick}
          {...attributes}
          {...listeners}
          {...dropListeners}
        >
          <Property
            menuOpened={propertyMenuOpened}
            onCloseMenu={handlePropertyMenuClose}
            onOpenMenu={handlePropertyMenuOpen}
            field={field}
          />
          {isOver && (
            <div
              className={`absolute bottom-0 top-0 z-10 w-0.5 bg-blue-500 ${
                dropPosition === DropPosition.Before ? 'left-[-1px]' : 'left-full'
              }`}
            />
          )}
          <GridResizer field={field} onWidthChange={(width) => setFieldWidth(width)} />
        </Button>
      </Tooltip>
      {open && (
        <GridFieldMenu
          anchorPosition={menuAnchorPosition}
          anchorReference={'anchorPosition'}
          field={field}
          open={open}
          onClose={handleMenuClose}
          onOpenPropertyMenu={handlePropertyMenuOpen}
          onOpenMenu={onOpenMenu}
        />
      )}
    </div>
  );
};
