import { Database } from '$app/interfaces/database';
import { VirtualItem } from '@tanstack/react-virtual';
import { FC } from 'react';
import { useDatabase } from '../../database.hooks';
import { GridCell } from '../GridCell';

export const GridCellRow: FC<{
  columnVirtualItems: VirtualItem[];
  row: Database.Row;
  before: number;
  after: number;
}> = ({ columnVirtualItems, row, before, after }) => {
  const { fields } = useDatabase();

  return (
    <>
      <div className="flex">
        {before > 0 && <div style={{ width: before }} />}
        {columnVirtualItems.map(virtualColumn => (
          <div
            key={virtualColumn.key}
            className="border-r border-line-divider overflow-hidden"
            data-index={virtualColumn.index}
            style={{
              width: virtualColumn.size,
            }}
          >
            <GridCell rowId={row.id} field={fields[virtualColumn.index]} />
          </div>
        ))}
        {after > 0 && <div style={{ width: after }} />}
      </div>
      <div className="w-44 grow" />
    </>
  );
}