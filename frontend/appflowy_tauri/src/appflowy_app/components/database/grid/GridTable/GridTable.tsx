import { useVirtualizer } from '@tanstack/react-virtual';
import { FC, useMemo, useRef } from 'react';
import { RowMeta } from '../../application';
import { useDatabase } from '../../Database.hooks';
import { VirtualizedList } from '../../_shared';
import { GridRow, RenderRow, RenderRowType, rowMetasToRenderRow } from '../GridRow';

const getRenderRowKey = (row: RenderRow) => {
  if (row.type === RenderRowType.Row) {
    return `row:${row.data.meta.id}`;
  }

  return row.type;
};

export const GridTable: FC<{ tableHeight: number }> = ({ tableHeight }) => {
  const verticalScrollElementRef = useRef<HTMLDivElement | null>(null);
  const horizontalScrollElementRef = useRef<HTMLDivElement | null>(null);
  const { rowMetas, fields } = useDatabase();
  const renderRows = useMemo<RenderRow[]>(() => rowMetasToRenderRow(rowMetas as RowMeta[]), [rowMetas]);

  const rowVirtualizer = useVirtualizer<HTMLDivElement, HTMLDivElement>({
    count: renderRows.length,
    overscan: 20,
    getItemKey: (i) => getRenderRowKey(renderRows[i]),
    getScrollElement: () => verticalScrollElementRef.current,
    estimateSize: () => 37,
  });

  const columnVirtualizer = useVirtualizer<HTMLDivElement, HTMLDivElement>({
    horizontal: true,
    count: fields.length,
    overscan: 5,
    getItemKey: (i) => fields[i].id,
    getScrollElement: () => horizontalScrollElementRef.current,
    estimateSize: (i) => fields[i].width ?? 201,
  });

  const getPrevRowId = (id: string) => {
    const index = rowMetas.findIndex((rowMeta) => rowMeta.id === id);

    if (index === 0) {
      return null;
    }

    return rowMetas[index - 1].id;
  };

  return (
    <div
      style={{
        height: tableHeight,
      }}
      className={'flex w-full flex-col'}
    >
      <div
        className={'w-full flex-1 overflow-auto'}
        ref={(e) => {
          verticalScrollElementRef.current = e;
          horizontalScrollElementRef.current = e;
        }}
      >
        <VirtualizedList
          className='flex w-fit basis-full flex-col'
          virtualizer={rowVirtualizer}
          itemClassName='flex'
          renderItem={(index) => (
            <GridRow getPrevRowId={getPrevRowId} row={renderRows[index]} virtualizer={columnVirtualizer} />
          )}
        />
      </div>
    </div>
  );
};
