import React, { FC, useCallback, useMemo, useRef } from 'react';
import { RowMeta } from '$app/application/database';
import { useDatabaseRendered, useDatabaseVisibilityFields, useDatabaseVisibilityRows } from '../../Database.hooks';
import { fieldsToColumns, GridColumn, RenderRow, RenderRowType, rowMetasToRenderRow } from '../constants';
import { CircularProgress } from '@mui/material';
import { GridChildComponentProps, GridOnScrollProps, VariableSizeGrid as Grid } from 'react-window';
import AutoSizer from 'react-virtualized-auto-sizer';
import { GridCell } from 'src/appflowy_app/components/database/grid/grid_cell';
import { useGridColumn, useGridRow } from './GridTable.hooks';
import GridStickyHeader from '$app/components/database/grid/grid_sticky_header/GridStickyHeader';
import GridTableOverlay from '$app/components/database/grid/grid_overlay/GridTableOverlay';
import ReactDOM from 'react-dom';

export interface GridTableProps {
  onEditRecord: (rowId: string) => void;
}

export const GridTable: FC<GridTableProps> = React.memo(({ onEditRecord }) => {
  const rowMetas = useDatabaseVisibilityRows();
  const fields = useDatabaseVisibilityFields();
  const renderRows = useMemo<RenderRow[]>(() => rowMetasToRenderRow(rowMetas as RowMeta[]), [rowMetas]);
  const columns = useMemo<GridColumn[]>(() => fieldsToColumns(fields), [fields]);
  const ref = useRef<Grid<HTMLDivElement>>(null);
  const { columnWidth } = useGridColumn(columns, ref);
  const { rowHeight } = useGridRow();
  const onRendered = useDatabaseRendered();

  const getItemKey = useCallback(
    ({ columnIndex, rowIndex }: { columnIndex: number; rowIndex: number }) => {
      const row = renderRows[rowIndex];
      const column = columns[columnIndex];

      const field = column.field;

      if (row.type === RenderRowType.Row) {
        if (field) {
          return `${row.data.meta.id}:${field.id}`;
        }

        return `${row.data.meta.id}:${column.type}`;
      }

      if (field) {
        return `${row.type}:${field.id}`;
      }

      return `${row.type}:${column.type}`;
    },
    [columns, renderRows]
  );

  const getContainerRef = useCallback(() => {
    return containerRef;
  }, []);

  const Cell = useCallback(
    ({ columnIndex, rowIndex, style }: GridChildComponentProps) => {
      const row = renderRows[rowIndex];
      const column = columns[columnIndex];

      return (
        <GridCell
          getContainerRef={getContainerRef}
          onEditRecord={onEditRecord}
          columnIndex={columnIndex}
          style={style}
          row={row}
          column={column}
        />
      );
    },
    [columns, getContainerRef, renderRows, onEditRecord]
  );

  const staticGrid = useRef<Grid<HTMLDivElement> | null>(null);

  const onScroll = useCallback(({ scrollLeft, scrollUpdateWasRequested }: GridOnScrollProps) => {
    if (!scrollUpdateWasRequested) {
      staticGrid.current?.scrollTo({ scrollLeft, scrollTop: 0 });
    }
  }, []);

  const containerRef = useRef<HTMLDivElement | null>(null);
  const scrollElementRef = useRef<HTMLDivElement | null>(null);

  const getScrollElement = useCallback(() => {
    return scrollElementRef.current;
  }, []);

  return (
    <div className={'flex w-full flex-1 flex-col '}>
      {fields.length === 0 && (
        <div className={'absolute left-0 top-0 z-10 flex h-full w-full items-center justify-center bg-bg-body'}>
          <CircularProgress />
        </div>
      )}
      <div className={'h-[36px]'}>
        <GridStickyHeader ref={staticGrid} getScrollElement={getScrollElement} columns={columns} />
      </div>

      <div className={'flex-1'}>
        <AutoSizer>
          {({ height, width }: { height: number; width: number }) => (
            <Grid
              ref={ref}
              onScroll={onScroll}
              columnCount={columns.length}
              columnWidth={columnWidth}
              height={height}
              rowCount={renderRows.length}
              rowHeight={rowHeight}
              width={width}
              overscanRowCount={10}
              itemKey={getItemKey}
              style={{
                overscrollBehavior: 'none',
              }}
              className={'grid-scroll-container'}
              outerRef={(el) => {
                scrollElementRef.current = el;
                onRendered();
              }}
              innerRef={containerRef}
            >
              {Cell}
            </Grid>
          )}
        </AutoSizer>
        {containerRef.current
          ? ReactDOM.createPortal(
              <GridTableOverlay getScrollElement={getScrollElement} containerRef={containerRef} />,
              containerRef.current
            )
          : null}
      </div>
    </div>
  );
});
