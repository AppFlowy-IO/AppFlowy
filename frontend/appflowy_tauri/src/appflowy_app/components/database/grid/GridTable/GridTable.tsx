import { useVirtualizer } from '@tanstack/react-virtual';
import { FC, useMemo, useRef } from 'react';
import { RowMeta } from '../../application';
import { useDatabase, useVerticalScrollElement } from '../../Database.hooks';
import { VirtualizedList } from '../../_shared';
import { GridRow, RenderRow, RenderRowType, rowMetasToRenderRow } from '../GridRow';

const getRenderRowKey = (row: RenderRow) => {
  if (row.type === RenderRowType.Row) {
    return `row:${row.data.meta.id}`;
  }

  return row.type;
};

export const GridTable: FC = () => {
  const verticalScrollElementRef = useVerticalScrollElement();
  const horizontalScrollElementRef = useRef<HTMLDivElement>(null);
  const { rowMetas, fields } = useDatabase();

  const renderRows = useMemo<RenderRow[]>(() => rowMetasToRenderRow(rowMetas as RowMeta[]), [rowMetas]);

  const rowVirtualizer = useVirtualizer({
    count: renderRows.length,
    overscan: 10,
    getItemKey: i => getRenderRowKey(renderRows[i]),
    getScrollElement: () => verticalScrollElementRef.current,
    estimateSize: () => 37,
  });

  const columnVirtualizer = useVirtualizer<Element, Element>({
    horizontal: true,
    count: fields.length,
    overscan: 5,
    getItemKey: i => fields[i].id,
    getScrollElement: () => horizontalScrollElementRef.current,
    estimateSize: (i) => fields[i].width ?? 201,
  });

  return (
    <div
      ref={horizontalScrollElementRef}
      className="flex w-full overflow-x-auto px-16"
      style={{ minHeight: 'calc(100% - 132px)' }}
    >
      <VirtualizedList
        className="flex flex-col basis-full"
        virtualizer={rowVirtualizer}
        itemClassName="flex"
        renderItem={index => (
          <GridRow row={renderRows[index]} virtualizer={columnVirtualizer} />
        )}
      />
    </div>
  );
};
