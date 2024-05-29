import { DEFAULT_ROW_HEIGHT } from '@/application/database-yjs/const';
import { AFScroller } from '@/components/_shared/scroller';
import { GridColumnType, RenderColumn } from '../grid-column';
import { GridCalculateRowCell, GridRowCell, RenderRowType, useRenderRows } from '../grid-row';
import React, { useCallback, useEffect, useRef } from 'react';
import AutoSizer from 'react-virtualized-auto-sizer';
import { GridChildComponentProps, VariableSizeGrid } from 'react-window';

export interface GridTableProps {
  onScrollLeft: (left: number) => void;
  columnWidth: (index: number, totalWidth: number) => number;

  columns: RenderColumn[];
  scrollLeft?: number;
  viewId: string;
}

export const GridTable = ({ scrollLeft, columnWidth, columns, onScrollLeft }: GridTableProps) => {
  const ref = useRef<VariableSizeGrid | null>(null);
  const { rows } = useRenderRows();
  const rowHeights = useRef<{ [key: string]: number }>({});

  useEffect(() => {
    if (ref.current) {
      ref.current.scrollTo({ scrollLeft });
    }
  }, [scrollLeft]);

  useEffect(() => {
    if (ref.current) {
      ref.current.resetAfterIndices({ columnIndex: 0, rowIndex: 0 });
    }
  }, [columns]);

  const rowHeight = useCallback(
    (index: number) => {
      const row = rows[index];

      if (!row || !row.rowId) return DEFAULT_ROW_HEIGHT;

      return rowHeights.current[row.rowId] || DEFAULT_ROW_HEIGHT;
    },
    [rows]
  );

  const setRowHeight = useCallback(
    (index: number, height: number) => {
      const row = rows[index];
      const rowId = row.rowId;

      if (!row || !rowId) return;
      const oldHeight = rowHeights.current[rowId];

      rowHeights.current[rowId] = Math.max(oldHeight || DEFAULT_ROW_HEIGHT, height);
      if (oldHeight !== height) {
        ref.current?.resetAfterRowIndex(index, true);
      }
    },
    [rows]
  );

  const onResize = useCallback(
    (rowIndex: number, columnIndex: number, size: { width: number; height: number }) => {
      setRowHeight(rowIndex, size.height);
    },
    [setRowHeight]
  );

  const getItemKey = useCallback(
    ({ columnIndex, rowIndex }: { columnIndex: number; rowIndex: number }) => {
      const row = rows[rowIndex];
      const column = columns[columnIndex];
      const fieldId = column.fieldId;

      if (row.type === RenderRowType.Row) {
        if (fieldId) {
          return `${row.rowId}:${fieldId}`;
        }

        return `${rowIndex}:${columnIndex}`;
      }

      if (fieldId) {
        return `${row.type}:${fieldId}`;
      }

      return `${rowIndex}:${columnIndex}`;
    },
    [columns, rows]
  );
  const Cell = useCallback(
    ({ columnIndex, rowIndex, style, data }: GridChildComponentProps) => {
      const row = data.rows[rowIndex];
      const column = data.columns[columnIndex] as RenderColumn;

      const classList = ['flex', 'items-center', 'overflow-hidden', 'grid-row-cell'];

      if (column.wrap) {
        classList.push('wrap-cell');
      } else {
        classList.push('whitespace-nowrap');
      }

      if (column.type === GridColumnType.Field) {
        classList.push('border-b', 'border-l', 'border-line-divider', 'px-2');
      }

      if (column.type === GridColumnType.NewProperty) {
        classList.push('border-b', 'border-line-divider', 'px-2');
      }

      if (row.type === RenderRowType.Row) {
        return (
          <div
            data-row-id={row.rowId}
            className={classList.join(' ')}
            style={{ ...style, borderLeftWidth: columnIndex === 1 || column.type === GridColumnType.Action ? 0 : 1 }}
          >
            <GridRowCell
              onResize={onResize}
              rowIndex={rowIndex}
              rowId={row.rowId}
              columnIndex={columnIndex}
              fieldId={column.fieldId}
              type={column.type}
            />
          </div>
        );
      }

      if (row.type === RenderRowType.CalculateRow && column.fieldId) {
        return (
          <div style={style}>
            <GridCalculateRowCell fieldId={column.fieldId} />
          </div>
        );
      }

      return <div style={style} />;
    },
    [onResize]
  );

  return (
    <AutoSizer>
      {({ height, width }: { height: number; width: number }) => (
        <VariableSizeGrid
          ref={ref}
          height={height}
          width={width}
          onScroll={({ scrollLeft }) => onScrollLeft(scrollLeft)}
          rowCount={rows.length}
          columnCount={columns.length}
          columnWidth={(index) => columnWidth(index, width)}
          rowHeight={rowHeight}
          className={'grid-table'}
          overscanRowCount={5}
          overscanColumnCount={5}
          style={{
            overscrollBehavior: 'none',
          }}
          itemKey={getItemKey}
          itemData={{ columns, rows }}
          outerElementType={AFScroller}
        >
          {Cell}
        </VariableSizeGrid>
      )}
    </AutoSizer>
  );
};

export default GridTable;
