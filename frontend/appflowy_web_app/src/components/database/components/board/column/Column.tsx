import { Row, useDatabaseContext } from '@/application/database-yjs';
import { AFScroller } from '@/components/_shared/scroller';
import ListItem from '@/components/database/components/board/column/ListItem';
import { useRenderColumn } from '@/components/database/components/board/column/useRenderColumn';
import { useMeasureHeight } from '@/components/database/components/cell/useMeasure';
import React, { memo, useCallback, useEffect, useMemo, useRef } from 'react';
import AutoSizer from 'react-virtualized-auto-sizer';
import { VariableSizeList } from 'react-window';
import { debounce } from 'lodash-es';

export interface ColumnProps {
  id: string;
  rows?: Row[];
  fieldId: string;
  onRendered?: (height: number) => void;
}

export const Column = memo(
  ({ id, rows, fieldId, onRendered }: ColumnProps) => {
    const { header } = useRenderColumn(id, fieldId);
    const ref = React.useRef<VariableSizeList | null>(null);
    const containerRef = useRef<HTMLDivElement>(null);
    const forceUpdate = useCallback((index: number) => {
      ref.current?.resetAfterIndex(index, true);
    }, []);
    const context = useDatabaseContext();
    const isDocumentBlock = context.isDocumentBlock;

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
      [rows],
    );
    const { rowHeight, onResize } = useMeasureHeight({ forceUpdate, rows: measureRows });
    const rowCount = rows?.length || 0;

    const calculateHeight = useMemo(() => debounce(() => {
      const el = containerRef.current;

      if (!el) return;

      if (rowCount === 0 || !isDocumentBlock) {
        onRendered?.(100);
        return;
      }

      const rows = el.querySelectorAll('.list-item');

      const maxBottom = Math.max(...Array.from(rows).map((row) => row.getBoundingClientRect().bottom));
      const height = maxBottom - el.getBoundingClientRect().top;

      onRendered?.(height + 100);
    }, 500), [onRendered, rowCount, isDocumentBlock]);

    useEffect(() => {

      calculateHeight();

      return () => {
        calculateHeight.cancel();
      };
    }, [calculateHeight]);

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

        return <ListItem
          fieldId={fieldId}
          onResize={onResizeCallback}
          item={item}
          style={style}
        />;
      },
      [fieldId, onResize],
    );

    const getItemSize = useCallback(
      (index: number) => {
        if (!rows || index >= rows.length) return 0;
        const row = rows[index];

        if (!row) return 0;
        return rowHeight(index);
      },
      [rowHeight, rows],
    );

    return (
      <div
        ref={containerRef}
        key={id}
        className="column rounded-[8px] flex w-[230px] flex-col gap-[10px]"
      >
        <div
          className="column-header flex overflow-hidden items-center gap-2 text-sm font-medium whitespace-nowrap"
        >
          <div className={'max-w-[180px] w-auto overflow-hidden'}>{header}</div>
          <span className={'text-text-caption font-medium'}>{rowCount}</span>
        </div>

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
  (prev, next) => JSON.stringify(prev) === JSON.stringify(next),
);
