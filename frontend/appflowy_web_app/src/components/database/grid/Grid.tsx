import { RowsContext, useDatabase, useRowOrdersSelector, useViewId } from '@/application/database-yjs';
import { useRenderFields, GridHeader, GridTable } from '@/components/database/components/grid';
import { CircularProgress } from '@mui/material';
import React, { useEffect, useState } from 'react';

export function Grid() {
  const database = useDatabase();
  const viewId = useViewId() || '';
  const [scrollLeft, setScrollLeft] = useState(0);

  const { fields, columnWidth } = useRenderFields();
  const rowOrders = useRowOrdersSelector();

  useEffect(() => {
    setScrollLeft(0);
  }, [viewId]);

  if (!database || !rowOrders) {
    return (
      <div className={'flex w-full flex-1 flex-col items-center justify-center'}>
        <CircularProgress />
      </div>
    );
  }

  return (
    <RowsContext.Provider
      value={{
        rowOrders,
      }}
    >
      <div className={'database-grid flex w-full flex-1 flex-col'}>
        <GridHeader scrollLeft={scrollLeft} columnWidth={columnWidth} columns={fields} onScrollLeft={setScrollLeft} />
        <div className={'grid-scroll-table w-full flex-1'}>
          <GridTable
            viewId={viewId}
            scrollLeft={scrollLeft}
            columnWidth={columnWidth}
            columns={fields}
            onScrollLeft={setScrollLeft}
          />
        </div>
      </div>
    </RowsContext.Provider>
  );
}

export default Grid;
