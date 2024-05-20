import { DEFAULT_ROW_HEIGHT, useReadOnly, useRowsSelector } from '@/application/database-yjs';

import { useMemo } from 'react';

export enum RenderRowType {
  Row = 'row',
  NewRow = 'new-row',
  CalculateRow = 'calculate-row',
}

export type RenderRow = {
  type: RenderRowType;
  rowId?: string;
  height?: number;
};

export function useRenderRows() {
  const rows = useRowsSelector();
  const readOnly = useReadOnly();

  const renderRows = useMemo(() => {
    return [
      ...rows.map((row) => ({
        type: RenderRowType.Row,
        rowId: row.id,
        height: row.height,
      })),

      !readOnly && {
        type: RenderRowType.NewRow,
        height: DEFAULT_ROW_HEIGHT,
      },
      {
        type: RenderRowType.CalculateRow,
        height: DEFAULT_ROW_HEIGHT,
      },
    ].filter(Boolean) as RenderRow[];
  }, [readOnly, rows]);

  return {
    rows: renderRows,
  };
}
