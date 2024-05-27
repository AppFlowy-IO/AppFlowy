import { Row } from '@/application/database-yjs';
import { AFScroller } from '@/components/_shared/scroller';
import { Tag } from '@/components/_shared/tag';
import ListItem from '@/components/database/components/board/column/ListItem';
import { useRenderColumn } from '@/components/database/components/board/column/useRenderColumn';
import { useMeasureHeight } from '@/components/database/components/cell/useMeasure';
import React, { useCallback, useEffect, useMemo } from 'react';
import { Draggable, DraggableProvided, Droppable } from 'react-beautiful-dnd';
import AutoSizer from 'react-virtualized-auto-sizer';
import { VariableSizeList } from 'react-window';

export interface ColumnProps {
  id: string;
  rows?: Row[];
  fieldId: string;
  provided: DraggableProvided;
}

export function Column({ id, rows, fieldId, provided }: ColumnProps) {
  const { header } = useRenderColumn(id, fieldId);
  const ref = React.useRef<VariableSizeList | null>(null);
  const forceUpdate = useCallback((index: number) => {
    ref.current?.resetAfterIndex(index, true);
  }, []);

  useEffect(() => {
    forceUpdate(0);
  }, [rows, forceUpdate]);

  const measureRows = useMemo(
    () =>
      rows?.map((row) => {
        return {
          rowId: row.id,
        };
      }) || [],
    [rows]
  );
  const { rowHeight, onResize } = useMeasureHeight({ forceUpdate, rows: measureRows });

  const Row = useCallback(
    ({ index, style, data }: { index: number; style: React.CSSProperties; data: Row[] }) => {
      const item = data[index];

      // We are rendering an extra item for the placeholder
      if (!item) {
        return null;
      }

      const onResizeCallback = (height: number) => {
        onResize(index, 0, {
          width: 0,
          height: height + 8,
        });
      };

      return (
        <Draggable isDragDisabled draggableId={item.id} index={index} key={item.id}>
          {(provided) => (
            <ListItem fieldId={fieldId} onResize={onResizeCallback} provided={provided} item={item} style={style} />
          )}
        </Draggable>
      );
    },
    [fieldId, onResize]
  );

  const getItemSize = useCallback(
    (index: number) => {
      if (!rows || index >= rows.length) return 0;
      const row = rows[index];

      if (!row) return 0;
      return rowHeight(index);
    },
    [rowHeight, rows]
  );

  if (!rows) return <div ref={provided.innerRef} />;
  return (
    <div key={id} className='column flex w-[230px] flex-col gap-4' {...provided.draggableProps} ref={provided.innerRef}>
      <div className='column-header flex h-[24px] items-center text-xs font-medium' {...provided.dragHandleProps}>
        <Tag label={header?.name} color={header?.color} />
      </div>

      <div className={'w-full flex-1 overflow-hidden'}>
        <Droppable
          droppableId={`column-${id}`}
          mode='virtual'
          renderClone={(provided, snapshot, rubric) => (
            <ListItem
              provided={provided}
              isDragging={snapshot.isDragging}
              item={rows[rubric.source.index]}
              fieldId={fieldId}
            />
          )}
        >
          {(provided, snapshot) => {
            // Add an extra item to our list to make space for a dragging item
            // Usually the DroppableProvided.placeholder does this, but that won't
            // work in a virtual list
            const itemCount = snapshot.isUsingPlaceholder ? rows.length + 1 : rows.length;

            return (
              <AutoSizer>
                {({ height, width }: { height: number; width: number }) => {
                  return (
                    <VariableSizeList
                      ref={ref}
                      height={height}
                      itemCount={itemCount}
                      itemSize={getItemSize}
                      width={width}
                      outerElementType={AFScroller}
                      outerRef={provided.innerRef}
                      itemData={rows}
                    >
                      {Row}
                    </VariableSizeList>
                  );
                }}
              </AutoSizer>
            );
          }}
        </Droppable>
      </div>
    </div>
  );
}
