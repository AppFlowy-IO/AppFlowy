import React, { useCallback, useState } from 'react';
import { GridChildComponentProps, GridOnScrollProps, VariableSizeGrid as Grid } from 'react-window';
import AutoSizer from 'react-virtualized-auto-sizer';
import { useGridColumn } from '$app/components/database/grid/grid_table';
import { GridField } from 'src/appflowy_app/components/database/grid/grid_field';
import NewProperty from '$app/components/database/components/property/NewProperty';
import { GridColumn, GridColumnType, RenderRow } from '$app/components/database/grid/constants';
import { OpenMenuContext } from '$app/components/database/grid/grid_sticky_header/GridStickyHeader.hooks';

const GridStickyHeader = React.forwardRef<
  Grid<GridColumn[]> | null,
  {
    columns: GridColumn[];
    getScrollElement?: () => HTMLDivElement | null;
    onScroll?: (props: GridOnScrollProps) => void;
  }
>(({ onScroll, columns, getScrollElement }, ref) => {
  const { columnWidth, resizeColumnWidth } = useGridColumn(
    columns,
    ref as React.MutableRefObject<Grid<
      | GridColumn[]
      | {
          columns: GridColumn[];
          renderRows: RenderRow[];
        }
    > | null>
  );

  const [openMenuId, setOpenMenuId] = useState<string | null>(null);

  const handleOpenMenu = useCallback((id: string) => {
    setOpenMenuId(id);
  }, []);

  const handleCloseMenu = useCallback((id: string) => {
    setOpenMenuId((prev) => {
      if (prev === id) {
        return null;
      }

      return prev;
    });
  }, []);

  const Cell = useCallback(
    ({ columnIndex, style, data }: GridChildComponentProps) => {
      const column = data[columnIndex];

      if (!column || column.type === GridColumnType.Action) return <div style={style} />;
      if (column.type === GridColumnType.NewProperty) {
        const width = (style.width || 0) as number;

        return (
          <div
            style={{
              ...style,
              width,
            }}
            className={'border-b border-r border-t border-line-divider'}
          >
            <NewProperty onInserted={setOpenMenuId} />
          </div>
        );
      }

      const field = column.field;

      if (!field) return <div style={style} />;

      return (
        <GridField
          className={'border-b border-r border-t border-line-divider'}
          style={style}
          onCloseMenu={handleCloseMenu}
          onOpenMenu={handleOpenMenu}
          resizeColumnWidth={(width: number) => resizeColumnWidth(columnIndex, width)}
          field={field}
          getScrollElement={getScrollElement}
        />
      );
    },
    [handleCloseMenu, handleOpenMenu, resizeColumnWidth, getScrollElement]
  );

  return (
    <OpenMenuContext.Provider value={openMenuId}>
      <AutoSizer>
        {({ height, width }: { height: number; width: number }) => {
          return (
            <Grid
              className={'grid-sticky-header w-full text-text-title'}
              height={height}
              width={width}
              rowHeight={() => 36}
              rowCount={1}
              columnCount={columns.length}
              columnWidth={columnWidth}
              ref={ref}
              onScroll={onScroll}
              itemData={columns}
              style={{ overscrollBehavior: 'none' }}
            >
              {Cell}
            </Grid>
          );
        }}
      </AutoSizer>
    </OpenMenuContext.Provider>
  );
});

export default GridStickyHeader;
