import { useVirtualizer } from '@tanstack/react-virtual';
import { FC, RefObject } from 'react';
import { RenderRow } from '../GridRow';

export interface VirtualizedRowsProps {
  rows: RenderRow[];
  scrollElementRef: RefObject<Element>;
  defaultHeight?: number;
  renderRow: (row: RenderRow, index: number) => React.ReactNode;
}

export const VirtualizedRows: FC<VirtualizedRowsProps> = ({
  rows,
  scrollElementRef,
  defaultHeight = 41,
  renderRow,
}) => {
  const virtualizer = useVirtualizer({
    count: rows.length,
    overscan: 5,
    getItemKey: i => {
      const row = rows[i];

      if (row.type === 'row') {
        return `row:${row.data.id}`;
      }

      return `fields`;
    },
    getScrollElement: () => scrollElementRef.current,
    estimateSize: i => {
      const row = rows[i];

      if (row.type === 'row') {
        return row.data.height ?? defaultHeight;
      }

      return defaultHeight;
    },
  });

  const virtualItems = virtualizer.getVirtualItems();

  return (
    <div
      style={{
        position: 'relative',
        height: virtualizer.getTotalSize(),
      }}
    >
      {virtualItems.map((virtualRow) => {
        return (
          <div
            key={virtualRow.key}
            className='absolute top-0 left-0 flex min-w-full border-b border-line-divider'
            style={{
              height: virtualRow.size,
              transform: `translateY(${virtualRow.start}px)`,
            }}
            data-key={virtualRow.key}
            data-index={virtualRow.index}
          >
            {renderRow(rows[virtualRow.index], virtualRow.index)}
          </div>
        );
      })}
    </div>
  );
};