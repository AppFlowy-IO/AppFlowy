import { useReadOnly } from '@/application/database-yjs';
import { DEFAULT_ROW_HEIGHT } from '@/application/database-yjs/const';
import { useGridRowsSelector } from '@/application/database-yjs/selector';
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
  const rows = useGridRowsSelector();
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
