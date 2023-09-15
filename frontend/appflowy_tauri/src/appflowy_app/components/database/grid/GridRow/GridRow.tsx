import { VirtualItem } from '@tanstack/react-virtual';
import { FC } from 'react';
import { RenderRow, RenderRowType } from './constants';
import { GridCellRow } from './GridCellRow';
import { GridFieldRow } from './GridFieldRow';
import { GridNewRow } from './GridNewRow';

export const GridRow: FC<{
  row: RenderRow;
  columnVirtualItems: VirtualItem[];
  before: number;
  after: number;
}> = ({ row, columnVirtualItems, before, after }) => {

  switch (row.type) {
    case RenderRowType.Row:
      return (
        <GridCellRow
          row={row.data}
          columnVirtualItems={columnVirtualItems}
          before={before}
          after={after}
        />
      );
    case RenderRowType.Fields:
      return (
        <GridFieldRow
          columnVirtualItems={columnVirtualItems}
          before={before}
          after={after}
        />
      );
    case RenderRowType.NewRow:
      return <GridNewRow />;
    default:
      return null;
  }
};