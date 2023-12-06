import React, { useCallback, useState } from 'react';
import { GridChildComponentProps, VariableSizeGrid as Grid } from 'react-window';
import AutoSizer from 'react-virtualized-auto-sizer';
import { useGridColumn } from '$app/components/database/grid/GridTable/GridTable.hooks';
import { GridField } from '$app/components/database/grid/GridField';
import NewProperty from '$app/components/database/components/property/NewProperty';
import { GridColumn, GridColumnType } from '$app/components/database/grid/constants';
import { OpenMenuContext } from '$app/components/database/grid/GridStickyHeader/GridStickyHeader.hooks';

const GridStickyHeader = React.forwardRef<
  Grid<HTMLDivElement> | null,
  { columns: GridColumn[]; getScrollElement?: () => HTMLDivElement | null }
>(({ columns, getScrollElement }, ref) => {
  const { columnWidth, resizeColumnWidth } = useGridColumn(
    columns,
    ref as React.MutableRefObject<Grid<HTMLDivElement> | null>
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
    ({ columnIndex, style }: GridChildComponentProps) => {
      const column = columns[columnIndex];

      if (column.type === GridColumnType.NewProperty) {
        const width = (style.width || 0) as number;

        return (
          <div
            style={{
              ...style,
              width: width + 8,
            }}
            className={'border-b border-r border-t border-line-divider'}
          >
            <NewProperty onInserted={setOpenMenuId} />
          </div>
        );
      }

      if (column.type === GridColumnType.Action) {
        return <div style={style} />;
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
    [columns, handleCloseMenu, handleOpenMenu, resizeColumnWidth, getScrollElement]
  );

  return (
    <OpenMenuContext.Provider value={openMenuId}>
      <AutoSizer>
        {({ height, width }: { height: number; width: number }) => {
          return (
            <Grid
              height={height}
              width={width}
              rowHeight={() => 36}
              rowCount={1}
              columnCount={columns.length}
              columnWidth={columnWidth}
              ref={ref}
              style={{ overflowX: 'hidden', overscrollBehavior: 'none' }}
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
