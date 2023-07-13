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
import { DatabaseFilterPopup } from '$app/components/_shared/DatabaseFilter/DatabaseFilterPopup';
import { DatabaseSortPopup } from '$app/components/_shared/DatabaseSort/DatabaseSortPopup';

export const Grid = ({ viewId }: { viewId: string }) => {
  const { controller, rows, groups } = useDatabase(viewId, ViewLayoutPB.Grid);
  const [showGridRow, setShowGridRow] = useState(false);
  const [boardRowInfo, setBoardRowInfo] = useState<RowInfo>();
  const [showFilterPopup, setShowFilterPopup] = useState(false);
  const [showSortPopup, setShowSortPopup] = useState(false);

  const onOpenRow = (rowInfo: RowInfo) => {
    setBoardRowInfo(rowInfo);
    setShowGridRow(true);
  };

  const onShowFilterClick = () => {
    setShowFilterPopup(true);
  };

  const onShowSortClick = () => {
    setShowSortPopup(true);
  };

  return (
    <>
      {controller && groups && (
        <>
          <div className='flex flex-1 flex-col gap-4'>
            <div className='flex w-full  items-center justify-between'>
              <GridTitle onShowFilterClick={onShowFilterClick} onShowSortClick={onShowSortClick} />
              <GridToolbar />
            </div>

            {/* table component view with text area for td */}
            <div className='flex flex-1 flex-col gap-4'>
              <div className='flex flex-1 flex-col overflow-x-auto'>
                <GridTableHeader controller={controller} onShowFilterClick={onShowFilterClick} />
                <div className={'relative flex-1'}>
                  <GridTableRows onOpenRow={onOpenRow} allRows={rows} viewId={viewId} controller={controller} />
                </div>
              </div>

              <GridAddRow controller={controller} />
            </div>

            <GridTableCount allRows={rows} />
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
      {showFilterPopup && <DatabaseFilterPopup onOutsideClick={() => setShowFilterPopup(false)} />}
      {showSortPopup && <DatabaseSortPopup onOutsideClick={() => setShowSortPopup(false)} />}
    </>
  );
};
