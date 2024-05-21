import { GridRowsContext, useDatabase, useGridRowOrders, useViewId } from '@/application/database-yjs';
import { useRenderColumns } from '@/components/database/components/grid-column';
import { CircularProgress } from '@mui/material';
import React, { useState } from 'react';
import { GridHeader } from 'src/components/database/components/grid-header';
import { GridTable } from 'src/components/database/components/grid-table';

export function Grid() {
  const database = useDatabase();
  const [scrollLeft, setScrollLeft] = useState(0);
  const viewId = useViewId() || '';
  const { columns, columnWidth } = useRenderColumns(viewId);
  const rowOrders = useGridRowOrders();

  if (!database || !rowOrders) {
    return (
      <div className={'flex w-full flex-1 flex-col items-center justify-center'}>
        <CircularProgress />
      </div>
    );
  }

  return (
    <GridRowsContext.Provider
      value={{
        rowOrders,
      }}
    >
      <div className={'flex w-full flex-1 flex-col'}>
        <GridHeader scrollLeft={scrollLeft} columnWidth={columnWidth} columns={columns} onScrollLeft={setScrollLeft} />
        <div className={'grid-scroll-table w-full flex-1'}>
          <GridTable
            viewId={viewId}
            scrollLeft={scrollLeft}
            columnWidth={columnWidth}
            columns={columns}
            onScrollLeft={setScrollLeft}
          />
        </div>
      </div>
    </GridRowsContext.Provider>
  );
}

export default Grid;
