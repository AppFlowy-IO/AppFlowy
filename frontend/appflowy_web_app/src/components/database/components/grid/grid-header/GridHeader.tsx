import React, { useCallback, useEffect, useRef } from 'react';
import { GridChildComponentProps, VariableSizeGrid } from 'react-window';
import AutoSizer from 'react-virtualized-auto-sizer';
import { GridColumnType, RenderColumn, GridColumn } from '../grid-column';

export interface GridHeaderProps {
  onScrollLeft: (left: number) => void;
  columnWidth: (index: number, totalWidth: number) => number;
  columns: RenderColumn[];
  scrollLeft?: number;
}

export const GridHeader = ({ scrollLeft, onScrollLeft, columnWidth, columns }: GridHeaderProps) => {
  const ref = useRef<VariableSizeGrid | null>(null);
  const Cell = useCallback(({ columnIndex, style, data }: GridChildComponentProps) => {
    const column = data[columnIndex];

    // Placeholder for Action toolbar
    if (!column || column.type === GridColumnType.Action) return <div style={style} />;

    if (column.type === GridColumnType.Field) {
      return (
        <div style={style}>
          <GridColumn column={column} index={columnIndex} />
        </div>
      );
    }

    return <div style={style} className={'border-t border-b border-line-divider'} />;
  }, []);

  useEffect(() => {
    if (ref.current) {
      ref.current.scrollTo({ scrollLeft });
    }
  }, [scrollLeft]);

  useEffect(() => {
    if (ref.current) {
      ref.current?.resetAfterIndices({ columnIndex: 0, rowIndex: 0 });
    }
  }, [columns]);

  return (
    <div className={'h-[36px] w-full'}>
      <AutoSizer>
        {({ height, width }: { height: number; width: number }) => {
          return (
            <VariableSizeGrid
              className={'grid-sticky-header w-full text-text-title'}
              height={height}
              width={width}
              rowHeight={() => 36}
              rowCount={1}
              columnCount={columns.length}
              columnWidth={(index) => columnWidth(index, width)}
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
