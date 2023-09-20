import { Virtualizer } from '@tanstack/react-virtual';
import { IconButton, Tooltip } from '@mui/material';
import { DragEventHandler, FC, useCallback, useContext, useMemo, useState } from 'react';
import { Database } from '$app/interfaces/database';
import { ReactComponent as DragSvg } from '$app/assets/drag.svg';
import { throttle } from '$app/utils/tool';
import { useDatabase, useViewId } from '../../database.hooks';
import * as service from '../../database_bd_svc';
import { DatabaseUIState } from '../../database.context';
import { GridCell } from '../GridCell';
import { DragItem, DragType, VirtualizedList, useDraggable, useDroppable } from '../../_shared';
import { GridCellRowActions } from './GridCellRowActions';
import { t } from 'i18next';

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
  const uiState = useContext(DatabaseUIState);
  const [ hover, setHover ] = useState(false);
  const [ openTooltip, setOpenTooltip ] = useState(false);
  const [ position, setPosition ] = useState<'before' | 'after'>();
  const {
    isDragging,
    attributes,
    listeners,
    setPreviewRef,
    previewRef,
  } = useDraggable({
    type: DragType.Row,
    data: {
      row,
    },
    onDragStart: useCallback(() => {
      uiState.enableVerticalAutoScroll = true;
    }, [uiState]),
    onDragEnd: useCallback(() => {
      uiState.enableVerticalAutoScroll = false;
    }, [uiState]),
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
    onDragOver: useMemo<DragEventHandler>(() => {
      return throttle((event) => {
        const element = previewRef.current;

        if (!element) {
          return;
        }

        const { top, bottom } = element.getBoundingClientRect();
        const middle = (top + bottom) / 2;

        setPosition(event.clientY < middle ? 'before' : 'after');
      }, 20);
    }, [previewRef]),
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
      className="flex grow ml-[-49px]"
      onMouseEnter={handleMouseEnter}
      onMouseLeave={handleMouseLeave}
      {...dropListeners}
    >
      <GridCellRowActions
        className={hover ? 'visible' : 'invisible'}
        rowId={row.id}
      >
        <Tooltip
          placement="top"
          title={t('grid.row.drag')}
          open={openTooltip && !isDragging}
          onClose={() => setOpenTooltip(false)}
          onOpen={() => setOpenTooltip(true)}
        >
          <IconButton
            className="mx-1 cursor-grab active:cursor-grabbing"
            {...attributes}
            {...listeners}
          >
            <DragSvg className='-mx-1' />
          </IconButton>
        </Tooltip>
      </GridCellRowActions>
      <div
        ref={setPreviewRef}
        className={`flex grow border-b border-line-divider relative ${isDragging ? 'bg-blue-50' : ''}`}
      >
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
        {isOver && <div className={`absolute left-0 right-0 h-0.5 bg-blue-500 z-10 ${position === 'before' ? 'top-[-1px]' : 'top-full'}`} />}
      </div>
    </div>
  );
};
