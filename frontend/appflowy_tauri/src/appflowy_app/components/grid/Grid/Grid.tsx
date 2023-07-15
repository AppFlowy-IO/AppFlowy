import { useDatabase } from '$app/components/_shared/database-hooks/useDatabase';
import { GridTableCount } from '../GridTableCount/GridTableCount';
import { GridTableHeader } from '../GridTableHeader/GridTableHeader';
import { GridAddRow } from '../GridTableRows/GridAddRow';
import { GridTableRows } from '../GridTableRows/GridTableRows';
import { GridTitle } from '../GridTitle/GridTitle';
import { GridToolbar } from '../GridToolbar/GridToolbar';
import { EditRow } from '$app/components/_shared/EditRow/EditRow';
import { useState } from 'react';
import { RowInfo } from '$app/stores/effects/database/row/row_cache';
import { ViewLayoutPB } from '@/services/backend';

export const Grid = ({ viewId }: { viewId: string }) => {
  const { controller, rows, groups } = useDatabase(viewId, ViewLayoutPB.Grid);
  const [showGridRow, setShowGridRow] = useState(false);
  const [boardRowInfo, setBoardRowInfo] = useState<RowInfo>();

  const onOpenRow = (rowInfo: RowInfo) => {
    setBoardRowInfo(rowInfo);
    setShowGridRow(true);
  };

  return (
    <>
      {controller && groups && (
        <>
          <div className='mx-auto mt-8 flex flex-col gap-8 px-8'>
            <div className='flex w-full  items-center justify-between'>
              <GridTitle />
              <GridToolbar />
            </div>

            {/* table component page with text area for td */}
            <div className='flex flex-col gap-4'>
              <table className='w-full table-fixed text-sm'>
                <GridTableHeader controller={controller} />
                <GridTableRows onOpenRow={onOpenRow} allRows={rows} viewId={viewId} controller={controller} />
              </table>

              <GridAddRow controller={controller} />
            </div>

            <GridTableCount rows={rows} />
          </div>
          {showGridRow && boardRowInfo && (
            <EditRow
              onClose={() => setShowGridRow(false)}
              viewId={viewId}
              controller={controller}
              rowInfo={boardRowInfo}
            ></EditRow>
          )}
        </>
      )}
    </>
  );
};
