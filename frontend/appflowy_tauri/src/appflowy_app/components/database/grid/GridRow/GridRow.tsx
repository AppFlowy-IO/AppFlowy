import { VirtualItem } from '@tanstack/react-virtual';
import { FC } from 'react';
import { GridCellRow } from './GridCellRow';
import { GridFieldRow } from './GridFieldRow';
import { RenderRow, RenderRowType } from './constants';

export const GridRow: FC<{
  row: RenderRow;
  columnVirtualItems: VirtualItem[];
  before: number;
  after: number;
}> = ({ row, columnVirtualItems, before, after }) => {

  if (row.type === RenderRowType.Row) {
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
};