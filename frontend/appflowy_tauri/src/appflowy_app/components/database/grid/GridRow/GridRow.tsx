import React, { FC } from 'react';
import { RenderRow, RenderRowType } from './constants';
import { GridCellRow } from './GridCellRow';
import { GridNewRow } from './GridNewRow';
import { GridFieldRow } from '$app/components/database/grid/GridRow/GridFieldRow';
import GridCalculateRow from '$app/components/database/grid/GridRow/GridCalculateRow';

export interface GridRowProps {
  row: RenderRow;
  getPrevRowId: (id: string) => string | null;
  onEditRecord: (rowId: string) => void;
}

export const GridRow: FC<GridRowProps> = React.memo(({ row, getPrevRowId, onEditRecord }) => {
  switch (row.type) {
    case RenderRowType.Fields:
      return <GridFieldRow />;
    case RenderRowType.Row:
      return <GridCellRow onEditRecord={onEditRecord} rowMeta={row.data.meta} getPrevRowId={getPrevRowId} />;
    case RenderRowType.NewRow:
      return <GridNewRow startRowId={row.data.startRowId} groupId={row.data.groupId} />;
    case RenderRowType.CalculateRow:
      return <GridCalculateRow />;
    default:
      return null;
  }
});
