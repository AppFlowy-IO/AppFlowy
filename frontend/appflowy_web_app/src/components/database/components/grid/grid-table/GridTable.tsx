import { useDatabaseContext, useDatabaseViewId } from '@/application/database-yjs';
import { AFScroller } from '@/components/_shared/scroller';
import { useMeasureHeight } from '@/components/database/components/cell/useMeasure';
import React, { useCallback, useEffect, useRef } from 'react';
import AutoSizer from 'react-virtualized-auto-sizer';
import { GridChildComponentProps, VariableSizeGrid } from 'react-window';
import { GridColumnType, RenderColumn } from '../grid-column';
import { GridCalculateRowCell, GridRowCell, RenderRowType, useRenderRows } from '../grid-row';

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
  const viewId = useDatabaseViewId();

  const forceUpdate = useCallback((index: number) => {
    ref.current?.resetAfterRowIndex(index, true);
  }, []);

  const { rowHeight, onResize } = useMeasureHeight({ forceUpdate, rows });
  const context = useDatabaseContext();
  const onRendered = context.onRendered;
  const isDocumentBlock = context.isDocumentBlock;
  const readOnly = context.readOnly;

  const calculateTableHeight = useCallback(() => {
    const table = document.querySelector(`.grid-table-${viewId}`);
    const tableRect = table?.getBoundingClientRect();
    const theLastRow = table?.querySelector('.calculate-row-cell');
    const rowRect = theLastRow?.getBoundingClientRect();

    if (!tableRect) {
      onRendered?.(0);
      return;
    }

    if (rowRect) {
      const offset = readOnly ? 80 : 117;

      onRendered?.(rowRect.bottom - tableRect.top + offset);
    } else {
      onRendered?.(tableRect.height + 80);
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [viewId, readOnly]);

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
    const timeout = setTimeout(() => {
      calculateTableHeight();
    }, 500);

    return () => {
      clearTimeout(timeout);
    };

  }, [columns, resetGrid, calculateTableHeight]);

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
        classList.push('border-b', 'border-line-divider', 'px-2', 'grid-row-filed-cell');
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
          <div
            style={style}
            className={`${isDocumentBlock ? '' : 'pb-36'} calculate-row-cell`}
          >
            <GridCalculateRowCell fieldId={column.fieldId} />
          </div>
        );
      }

      return <div style={style} />;
    },
    [onResize, isDocumentBlock],
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
          className={`grid-table grid-table-${viewId}`}
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
