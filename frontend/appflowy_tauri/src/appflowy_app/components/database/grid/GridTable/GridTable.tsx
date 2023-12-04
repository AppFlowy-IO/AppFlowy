import { useVirtualizer } from '@tanstack/react-virtual';
import React, { FC, useCallback, useMemo, useRef } from 'react';
import { RowMeta } from '../../application';
import { useDatabaseVisibilityFields, useDatabaseVisibilityRows } from '../../Database.hooks';
import { VirtualizedList } from '../../_shared';
import { GridRow, RenderRow, RenderRowType, rowMetasToRenderRow } from '../GridRow';
import { CircularProgress } from '@mui/material';

const getRenderRowKey = (row: RenderRow) => {
  if (row.type === RenderRowType.Row) {
    return `row:${row.data.meta.id}`;
  }

  return row.type;
};

export interface GridTableProps {
  tableHeight: number;
  onEditRecord: (rowId: string) => void;
}
export const GridTable: FC<GridTableProps> = React.memo(({ tableHeight, onEditRecord }) => {
  const verticalScrollElementRef = useRef<HTMLDivElement | null>(null);
  const rowMetas = useDatabaseVisibilityRows();
  const fields = useDatabaseVisibilityFields();
  const renderRows = useMemo<RenderRow[]>(() => rowMetasToRenderRow(rowMetas as RowMeta[]), [rowMetas]);

  const rowVirtualizer = useVirtualizer<HTMLDivElement, HTMLDivElement>({
    count: renderRows.length,
    overscan: 15,
    getItemKey: (i) => getRenderRowKey(renderRows[i]),
    getScrollElement: () => verticalScrollElementRef.current,
    estimateSize: () => 37,
  });

  const getPrevRowId = useCallback(
    (id: string) => {
      const index = rowMetas.findIndex((rowMeta) => rowMeta.id === id);

      if (index === 0) {
        return null;
      }

      return rowMetas[index - 1].id;
    },
    [rowMetas]
  );

  return (
    <div
      style={{
        height: tableHeight,
      }}
      className={'flex h-full w-full flex-col'}
    >
      {fields.length === 0 && (
        <div className={'absolute left-0 top-0 z-10 flex h-full w-full items-center justify-center bg-bg-body'}>
          <CircularProgress />
        </div>
      )}
      <div className={'w-full flex-1 overflow-auto scroll-smooth'} ref={verticalScrollElementRef}>
        <VirtualizedList
          className='flex w-fit basis-full flex-col px-16'
          virtualizer={rowVirtualizer}
          itemClassName='flex'
          renderItem={(index) => (
            <GridRow onEditRecord={onEditRecord} getPrevRowId={getPrevRowId} row={renderRows[index]} />
          )}
        />
      </div>
    </div>
  );
});
