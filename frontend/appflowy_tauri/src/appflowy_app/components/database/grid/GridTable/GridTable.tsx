import { useVirtualizer } from '@tanstack/react-virtual';
import React, { FC, useMemo, useRef } from 'react';
import { RowMeta } from '../../application';
import { useDatabaseVisibilityFields, useDatabaseVisibilityRows } from '../../Database.hooks';
import { VirtualizedList } from '../../_shared';
import { DEFAULT_FIELD_WIDTH, GridRow, RenderRow, RenderRowType, rowMetasToRenderRow } from '../GridRow';

const getRenderRowKey = (row: RenderRow) => {
  if (row.type === RenderRowType.Row) {
    return `row:${row.data.meta.id}`;
  }

  return row.type;
};

export const GridTable: FC<{ tableHeight: number }> = React.memo(({ tableHeight }) => {
  const verticalScrollElementRef = useRef<HTMLDivElement | null>(null);
  const horizontalScrollElementRef = useRef<HTMLDivElement | null>(null);
  const rowMetas = useDatabaseVisibilityRows();
  const renderRows = useMemo<RenderRow[]>(() => rowMetasToRenderRow(rowMetas as RowMeta[]), [rowMetas]);
  const fields = useDatabaseVisibilityFields();
  const rowVirtualizer = useVirtualizer<HTMLDivElement, HTMLDivElement>({
    count: renderRows.length,
    overscan: 5,
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
    estimateSize: (i) => {
      return fields[i].width ?? DEFAULT_FIELD_WIDTH;
    },
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
          className='flex w-fit basis-full flex-col px-16'
          virtualizer={rowVirtualizer}
          itemClassName='flex'
          renderItem={(index) => (
            <GridRow getPrevRowId={getPrevRowId} row={renderRows[index]} virtualizer={columnVirtualizer} />
          )}
        />
      </div>
    </div>
  );
});
