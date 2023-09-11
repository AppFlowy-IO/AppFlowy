import { Virtualizer, useVirtualizer } from '@tanstack/react-virtual';
import { FC, useContext, useMemo, useRef } from 'react';
import { VerticalScrollElementRefContext } from '../../database.context';
import { useDatabase } from '../../database.hooks';
import { GridRow, RenderRow, RenderRowType } from '../GridRow';
import { VirtualizedRows } from './VirtualizedRows';

const calculateBeforeAfter = (columnVirtualizer: Virtualizer<HTMLDivElement, Element>) => {
  const columnVirtualItems = columnVirtualizer.getVirtualItems();

  return columnVirtualItems.length > 0
    ? [
      columnVirtualItems[0].start,
      columnVirtualizer.getTotalSize() - columnVirtualItems[columnVirtualItems.length - 1].end,
    ]
    : [0, 0];
};

export const GridTable: FC = () => {
  const verticalScrollElementRef = useContext(VerticalScrollElementRefContext);
  const { rows, fields } = useDatabase();

  const horizontalScrollElementRef = useRef<HTMLDivElement>(null);

  const renderRows = useMemo<RenderRow[]>(() => {
    return [
      {
        type: RenderRowType.Fields,
      },
      ...rows.map(row => ({
        type: RenderRowType.Row,
        data: row,
      })),
      {
        type: RenderRowType.NewRow,
      },
    ];
  }, [rows]);

  const defaultColumnWidth = 221;

  const columnVirtualizer = useVirtualizer({
    horizontal: true,
    count: fields.length,
    overscan: 5,
    getItemKey: i => fields[i].id,
    getScrollElement: () => horizontalScrollElementRef.current,
    estimateSize: (i) => fields[i].width ?? defaultColumnWidth,
  });

  const columnVirtualItems = columnVirtualizer.getVirtualItems();
  const [before, after] = calculateBeforeAfter(columnVirtualizer);

  return (
    <div
      ref={horizontalScrollElementRef}
      className="overflow-y-hidden overflow-x-auto"
    >
      <div className='px-16'>
        <VirtualizedRows
          scrollElementRef={verticalScrollElementRef}
          rows={renderRows}
          renderRow={(row) => (
            <GridRow
              row={row}
              columnVirtualItems={columnVirtualItems}
              before={before}
              after={after}
            />
          )}
        />
      </div>
    </div>
  );
};