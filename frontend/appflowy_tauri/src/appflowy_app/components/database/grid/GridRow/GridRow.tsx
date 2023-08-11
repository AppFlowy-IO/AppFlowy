import { VirtualItem } from '@tanstack/react-virtual';
import { FC } from 'react';
import { Database } from '$app/interfaces/database';
import { GridCellRow } from './GridCellRow';
import { GridFieldRow } from './GridFieldRow';

interface FieldRow {
  type: 'fields';
}

interface CellRow {
  type: 'row';
  data: Database.Row;
}

export type RenderRow = FieldRow | CellRow;

export const GridRow: FC<{
  row: RenderRow;
  columnVirtualItems: VirtualItem[];
  before: number;
  after: number;
}> = ({ row, columnVirtualItems, before, after }) => {

  if (row.type === 'row') {
    return (
      <GridCellRow
        row={row.data}
        columnVirtualItems={columnVirtualItems}
        before={before}
        after={after}
      />
    );
  }

  return (
    <GridFieldRow
      columnVirtualItems={columnVirtualItems}
      before={before}
      after={after}
    />
  );
}