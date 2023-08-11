import { useVirtualizer } from '@tanstack/react-virtual';
import { FC, useContext, useMemo, useRef } from 'react';
import { useSnapshot } from 'valtio';
import { database } from '$app/stores/database';
import { VerticalScrollElementRefContext } from './context';
import { GridRow, RenderRow } from '../GridRow';

export const GridTable: FC = () => {
  const verticalScrollElementRef = useContext(VerticalScrollElementRefContext);
  const snapshot = useSnapshot(database);
  const { rows, fields } = snapshot;

  const horizontalScrollElementRef = useRef<HTMLDivElement>(null);

  const defaultWidth = 221;
  const defaultHeight = 41;

  const renderRows = useMemo<RenderRow[]>(() => {
    return [
      {
        type: 'fields' as const,
      },
      ...rows.map(row => ({
        type: 'row' as const,
        data: row,
      })),
    ];
  }, [rows]);

  const rowVirtualizer = useVirtualizer({
    count: renderRows.length,
    overscan: 5,
    getItemKey: i => {
      const renderRow = renderRows[i];

      if (renderRow.type === 'row') {
        return `row:${renderRow.data.id}`;
      }

      return `fields`;
    },
    getScrollElement: () => verticalScrollElementRef.current,
    estimateSize: (i) => {
      const renderRow = renderRows[i];

      if (renderRow.type === 'row') {
        return renderRow.data.height ?? defaultHeight;
      }

      return defaultHeight;
    },
  });

  const columnVirtualizer = useVirtualizer({
    horizontal: true,
    count: fields.length,
    overscan: 5,
    getItemKey: i => fields[i].id,
    getScrollElement: () => horizontalScrollElementRef.current,
    estimateSize: (i) => fields[i].width ?? defaultWidth,
  });

  const columnVirtualItems = columnVirtualizer.getVirtualItems();
  const [before, after] = columnVirtualItems.length > 0
    ? [
        columnVirtualItems[0].start,
        columnVirtualizer.getTotalSize() - columnVirtualItems[columnVirtualItems.length - 1].end,
      ]
    : [0, 0]

  return (
    <div
      ref={horizontalScrollElementRef}
      className="overflow-y-hidden overflow-x-auto"
    >
      <div className='px-16'>
        <div
          style={{
            position: 'relative',
            height: rowVirtualizer.getTotalSize(),
          }}
        >
          {rowVirtualizer.getVirtualItems().map((virtualRow) => {
            const row = renderRows[virtualRow.index];
            const needMeasure = row.type !== 'row';

            return (
              <div
                ref={needMeasure ? rowVirtualizer.measureElement : undefined}
                key={virtualRow.key}
                className="absolute top-0 left-0 flex min-w-full border-b border-line-divider"
                style={{
                  height: needMeasure ? undefined : virtualRow.size,
                  transform: `translateY(${virtualRow.start}px)`,
                }}
                data-key={virtualRow.key}
                data-index={virtualRow.index}
              >
                <GridRow
                  row={row}
                  columnVirtualItems={columnVirtualItems}
                  before={before}
                  after={after}
                />
              </div>
            );
          })}
        </div>
      </div>
    </div>
  );
};