import { useVirtualizer } from '@tanstack/react-virtual';
import { FC, useContext, useMemo, useRef } from 'react';
import { VerticalScrollElementRefContext } from '../../database.context';
import { useDatabase } from '../../database.hooks';
import { VirtualizedList } from '../../_shared';
import { GridRow, RenderRow, RenderRowType } from '../GridRow';

const getRenderRowKey = (row: RenderRow) => {
  if (row.type === RenderRowType.Row) {
    return `row:${row.data.id}`;
  }

  return row.type;
};

const getRenderRowHeight = (row: RenderRow) => {
  const defaultRowHeight = 37;

  if (row.type === RenderRowType.Row) {
    return row.data.height ?? defaultRowHeight;
  }

  return defaultRowHeight;
};

export const GridTable: FC = () => {
  const verticalScrollElementRef = useContext(VerticalScrollElementRefContext);
  const horizontalScrollElementRef = useRef<HTMLDivElement>(null);
  const { rows, fields } = useDatabase();

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
      {
        type: RenderRowType.Calculate,
      },
    ];
  }, [rows]);

  const rowVirtualizer = useVirtualizer({
    count: renderRows.length,
    overscan: 10,
    getItemKey: i => getRenderRowKey(renderRows[i]),
    getScrollElement: () => verticalScrollElementRef.current,
    estimateSize: i => getRenderRowHeight(renderRows[i]),
  });

  const defaultColumnWidth = 221;
  const columnVirtualizer = useVirtualizer<Element, Element>({
    horizontal: true,
    count: fields.length,
    overscan: 5,
    getItemKey: i => fields[i].id,
    getScrollElement: () => horizontalScrollElementRef.current,
    estimateSize: (i) => fields[i].width ?? defaultColumnWidth,
  });

  return (
    <div
      ref={horizontalScrollElementRef}
      className="flex w-full overflow-x-auto"
      style={{ minHeight: 'calc(100% - 132px)' }}
    >
      <VirtualizedList
        className="flex flex-col basis-full px-16"
        virtualizer={rowVirtualizer}
        itemClassName="flex"
        renderItem={index => (
          <GridRow row={renderRows[index]} virtualizer={columnVirtualizer} />
        )}
      />
    </div>
  );
};
