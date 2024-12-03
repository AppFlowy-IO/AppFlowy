import { DEFAULT_ROW_HEIGHT } from '@/application/database-yjs';
import React, { memo, useCallback, useEffect, useRef } from 'react';
import { areEqual, GridChildComponentProps, VariableSizeGrid } from 'react-window';
import AutoSizer from 'react-virtualized-auto-sizer';
import { GridColumnType, RenderColumn, GridColumn } from '../grid-column';

export interface GridHeaderProps {
  onScrollLeft: (left: number) => void;
  columnWidth: (index: number, totalWidth: number) => number;
  columns: RenderColumn[];
  scrollLeft?: number;
}

const Cell = memo(({ columnIndex, style, data }: GridChildComponentProps) => {
  const column = data[columnIndex];

  // Placeholder for Action toolbar
  if (!column || column.type === GridColumnType.Action) return <div style={style} />;

  if (column.type === GridColumnType.Field) {
    return (
      <div style={style}>
        <GridColumn
          column={column}
          index={columnIndex}
        />
      </div>
    );
  }

  return <div
    style={style}
    className={'border-t border-b border-line-divider'}
  />;
}, areEqual);

export const GridHeader = ({ scrollLeft, onScrollLeft, columnWidth, columns }: GridHeaderProps) => {
  const ref = useRef<VariableSizeGrid | null>(null);

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

  return (
    <div className={'h-[36px] w-full'}>
      <AutoSizer onResize={resetGrid}>
        {({ height, width }: { height: number; width: number }) => {
          return (
            <VariableSizeGrid
              className={'grid-sticky-header w-full text-text-title'}
              height={height}
              width={width}
              rowHeight={() => DEFAULT_ROW_HEIGHT}
              rowCount={1}
              columnCount={columns.length}
              columnWidth={(index) => {
                return columnWidth(index, width);
              }}
              ref={ref}
              onScroll={(props) => {
                onScrollLeft(props.scrollLeft);
              }}
              itemData={columns}
              style={{ overscrollBehavior: 'none' }}
            >
              {Cell}
            </VariableSizeGrid>
          );
        }}
      </AutoSizer>
    </div>
  );
};

export default GridHeader;
