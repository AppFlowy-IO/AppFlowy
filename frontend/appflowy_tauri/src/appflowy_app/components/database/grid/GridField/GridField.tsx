import { Button, Tooltip } from '@mui/material';
import { DragEventHandler, FC, HTMLAttributes, memo, useCallback, useEffect, useMemo, useState } from 'react';
import { throttle } from '$app/utils/tool';
import { useViewId } from '$app/hooks';
import { DragItem, DropPosition, DragType, useDraggable, useDroppable, ScrollDirection } from '../../_shared';
import { fieldService, Field } from '../../application';
import { useDatabase } from '../../Database.hooks';
import { Property } from '$app/components/database/components/property';
import GridResizer from '$app/components/database/grid/GridField/GridResizer';
import GridFieldMenu from '$app/components/database/grid/GridField/GridFieldMenu';
import { areEqual } from 'react-window';
import { useOpenMenu } from '$app/components/database/grid/GridStickyHeader/GridStickyHeader.hooks';

export interface GridFieldProps extends HTMLAttributes<HTMLDivElement> {
  field: Field;
  onOpenMenu?: (id: string) => void;
  onCloseMenu?: (id: string) => void;
  resizeColumnWidth?: (width: number) => void;
  getScrollElement?: () => HTMLElement | null;
}

export const GridField: FC<GridFieldProps> = memo(
  ({ getScrollElement, resizeColumnWidth, onOpenMenu, onCloseMenu, field, ...props }) => {
    const menuOpened = useOpenMenu(field.id);
    const viewId = useViewId();
    const { fields } = useDatabase();
    const [openTooltip, setOpenTooltip] = useState(false);
    const [propertyMenuOpened, setPropertyMenuOpened] = useState(false);
    const [dropPosition, setDropPosition] = useState<DropPosition>(DropPosition.Before);

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
        getScrollElement,
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
      <div className={'flex w-full border-r border-line-divider bg-bg-body'} {...props}>
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
            className='relative flex h-full w-full items-center px-0'
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
            <GridResizer field={field} onWidthChange={resizeColumnWidth} />
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
  },
  areEqual
);
