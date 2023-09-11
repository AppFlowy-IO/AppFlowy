import { Database } from '$app/interfaces/database';
import { Virtualizer } from '@tanstack/react-virtual';
import { FC } from 'react';
import { useDatabase } from '../../database.hooks';
import { GridCell } from '../GridCell';
import { VirtualizedList } from '../_shared';

export interface GridCellRowProps {
  row: Database.Row;
  virtualizer: Virtualizer<Element, Element>;
}

export const GridCellRow: FC<GridCellRowProps> = ({
  row,
  virtualizer,
}) => {
  const { fields } = useDatabase();

  return (
    <div className="flex grow">
      <VirtualizedList
        className="flex"
        itemClassName="flex border-r border-line-divider"
        virtualizer={virtualizer}
        renderItem={index => (
          <GridCell
            rowId={row.id}
            field={fields[index]}
          />
        )}
      />
      <div className="min-w-20 grow" />
    </div>
  );
};
