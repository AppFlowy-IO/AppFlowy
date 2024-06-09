import React, { useCallback, useEffect, useState } from 'react';
import { DEFAULT_FIELD_WIDTH, GRID_ACTIONS_WIDTH, GridColumn, RenderRow } from '$app/components/database/grid/constants';
import { VariableSizeGrid as Grid } from 'react-window';

export function useGridRow() {
  const rowHeight = useCallback(() => {
    return 36;
  }, []);

  return {
    rowHeight,
  };
}

export function useGridColumn(
  columns: GridColumn[],
  ref: React.RefObject<Grid<
    | GridColumn[]
    | {
        columns: GridColumn[];
        renderRows: RenderRow[];
      }
  > | null>
) {
  const [columnWidths, setColumnWidths] = useState<number[]>([]);

  useEffect(() => {
    setColumnWidths(
      columns.map((field, index) => (index === 0 ? GRID_ACTIONS_WIDTH : field.width || DEFAULT_FIELD_WIDTH))
    );
    ref.current?.resetAfterColumnIndex(0);
  }, [columns, ref]);

  const resizeColumnWidth = useCallback(
    (index: number, width: number) => {
      setColumnWidths((columnWidths) => {
        if (columnWidths[index] === width) {
          return columnWidths;
        }

        const newColumnWidths = [...columnWidths];

        newColumnWidths[index] = width;

        return newColumnWidths;
      });

      if (ref.current) {
        ref.current.resetAfterColumnIndex(index);
      }
    },
    [ref]
  );

  const columnWidth = useCallback(
    (index: number) => {
      if (index === 0) return GRID_ACTIONS_WIDTH;
      return columnWidths[index] || DEFAULT_FIELD_WIDTH;
    },
    [columnWidths]
  );

  return {
    columnWidth,
    resizeColumnWidth,
  };
}
