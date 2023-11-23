import { Virtualizer } from '@tanstack/react-virtual';
import React, { FC } from 'react';
import { RenderRow, RenderRowType } from './constants';
import { GridCellRow } from './GridCellRow';
import { GridNewRow } from './GridNewRow';
import { GridFieldRow } from '$app/components/database/grid/GridRow/GridFieldRow';
import GridCalculateRow from '$app/components/database/grid/GridRow/GridCalculateRow';

export interface GridRowProps {
  row: RenderRow;
  virtualizer: Virtualizer<HTMLDivElement, HTMLDivElement>;
  getPrevRowId: (id: string) => string | null;
}

export const GridRow: FC<GridRowProps> = React.memo(({ row, virtualizer, getPrevRowId }) => {
  switch (row.type) {
    case RenderRowType.Fields:
      return <GridFieldRow />;
    case RenderRowType.Row:
      return <GridCellRow rowMeta={row.data.meta} virtualizer={virtualizer} getPrevRowId={getPrevRowId} />;
    case RenderRowType.NewRow:
      return <GridNewRow startRowId={row.data.startRowId} groupId={row.data.groupId} />;
    case RenderRowType.CalculateRow:
      return <GridCalculateRow />;
    default:
      return null;
  }
});
