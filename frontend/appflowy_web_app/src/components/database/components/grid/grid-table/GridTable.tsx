import { AFScroller } from '@/components/_shared/scroller';
import { useMeasureHeight } from '@/components/database/components/cell/useMeasure';
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

  const forceUpdate = useCallback((index: number) => {
    ref.current?.resetAfterRowIndex(index, true);
  }, []);

  const { rowHeight, onResize } = useMeasureHeight({ forceUpdate, rows });

  useEffect(() => {
    if (ref.current) {
      ref.current.scrollTo({ scrollLeft });
    }
  }, [scrollLeft]);

  const resetGrid = useCallback(() => {
    ref.current?.resetAfterIndices({ columnIndex: 0, rowIndex: 0 });
  }, []);

  useEffect(() => {
    resetGrid();
  }, [columns, resetGrid]);

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
    [columns, rows],
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
            style={{ ...style, borderLeftWidth: columnIndex === 0 || column.type === GridColumnType.Action ? 0 : 1 }}
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
          <div style={style} className={'pb-36'}>
            <GridCalculateRowCell fieldId={column.fieldId} />
          </div>
        );
      }

      return <div style={style} />;
    },
    [onResize],
  );

  return (
    <AutoSizer onResize={resetGrid}>
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
