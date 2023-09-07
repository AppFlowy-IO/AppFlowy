import { useVirtualizer } from '@tanstack/react-virtual';
import { FC, RefObject } from 'react';
import { RenderRow, RenderRowType } from '../GridRow';

export interface VirtualizedRowsProps {
  rows: RenderRow[];
  scrollElementRef: RefObject<Element>;
  defaultHeight?: number;
  renderRow: (row: RenderRow, index: number) => React.ReactNode;
}

const getRenderRowKey = (row: RenderRow) => {
  switch (row.type) {
    case RenderRowType.Row:
      return `row:${row.data.id}`;
    case RenderRowType.Fields:
      return 'fields';
    case RenderRowType.NewRow:
      return 'new-row';
    default:
      return '';
  }
};

const getRenderRowHeight = (row: RenderRow) => {
  switch (row.type) {
    case RenderRowType.Row:
      return row.data.height ?? 41;
    case RenderRowType.Fields:
      return 41;
    case RenderRowType.NewRow:
      return 36;
    default:
      return 0;
  }
};

export const VirtualizedRows: FC<VirtualizedRowsProps> = ({
  rows,
  scrollElementRef,
  renderRow,
}) => {
  const virtualizer = useVirtualizer({
    count: rows.length,
    overscan: 5,
    getItemKey: i => getRenderRowKey(rows[i]),
    getScrollElement: () => scrollElementRef.current,
    estimateSize: i => getRenderRowHeight(rows[i]),
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