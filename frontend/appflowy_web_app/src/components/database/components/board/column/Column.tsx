import { Row } from '@/application/database-yjs';
import { AFScroller } from '@/components/_shared/scroller';
import ListItem from '@/components/database/components/board/column/ListItem';
import { useRenderColumn } from '@/components/database/components/board/column/useRenderColumn';
import { useMeasureHeight } from '@/components/database/components/cell/useMeasure';
import React, { memo, useCallback, useEffect, useMemo } from 'react';
import AutoSizer from 'react-virtualized-auto-sizer';
import { VariableSizeList } from 'react-window';

export interface ColumnProps {
  id: string;
  rows?: Row[];
  fieldId: string;
}

export const Column = memo(
  ({ id, rows, fieldId }: ColumnProps) => {
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

        return <ListItem fieldId={fieldId} onResize={onResizeCallback} item={item} style={style} />;
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
    const rowCount = rows?.length || 0;

    return (
      <div key={id} className='column flex w-[230px] flex-col gap-4'>
        <div className='column-header flex h-[24px] items-center text-sm font-medium'>{header}</div>

        <div className={'w-full flex-1 overflow-hidden'}>
          <AutoSizer>
            {({ height, width }: { height: number; width: number }) => {
              return (
                <VariableSizeList
                  ref={ref}
                  height={height}
                  itemCount={rowCount}
                  itemSize={getItemSize}
                  width={width}
                  outerElementType={AFScroller}
                  itemData={rows}
                >
                  {Row}
                </VariableSizeList>
              );
            }}
          </AutoSizer>
        </div>
      </div>
    );
  },
  (prev, next) => JSON.stringify(prev) === JSON.stringify(next)
);
