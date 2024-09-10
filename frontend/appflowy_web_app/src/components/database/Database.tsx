import {
  GetViewRowsMap,
  LoadView,
  LoadViewMeta,
  YDatabase,
  YDoc,
  YjsDatabaseKey,
  YjsEditorKey,
} from '@/application/types';
import ComponentLoading from '@/components/_shared/progress/ComponentLoading';
import DatabaseRow from '@/components/database/DatabaseRow';
import DatabaseViews from '@/components/database/DatabaseViews';
import React, { Suspense, useCallback, useEffect, useState } from 'react';
import * as Y from 'yjs';
import { DatabaseContextProvider } from './DatabaseContext';

export interface Database2Props {
  doc: YDoc;
  getViewRowsMap?: GetViewRowsMap;
  loadView?: LoadView;
  navigateToView?: (viewId: string) => Promise<void>;
  loadViewMeta?: LoadViewMeta;
  viewId: string;
  iidName: string;
  rowId?: string;
  onChangeView: (viewId: string) => void;
  onOpenRow?: (rowId: string) => void;
  visibleViewIds: string[];
  iidIndex: string;
}

function Database ({
  doc,
  getViewRowsMap,
  navigateToView,
  loadViewMeta,
  loadView,
  viewId,
  iidIndex,
  iidName,
  visibleViewIds,
  rowId,
  onChangeView,
  onOpenRow,
}: Database2Props) {
  const database = doc.getMap(YjsEditorKey.data_section).get(YjsEditorKey.database) as YDatabase;

  const view = database.get(YjsDatabaseKey.views).get(iidIndex);

  const rowOrders = view.get(YjsDatabaseKey.row_orders);
  const [rowDocMap, setRowDocMap] = useState<Y.Map<YDoc> | null>(null);

  const handleUpdateRowDocMap = useCallback(async () => {
    if (!getViewRowsMap || !iidIndex) return;

    const { rows, destroy } = await getViewRowsMap(iidIndex);

    setRowDocMap(rows);
    return destroy;
  }, [getViewRowsMap, iidIndex]);

  useEffect(() => {
    void handleUpdateRowDocMap();

    rowOrders?.observe(handleUpdateRowDocMap);
    return () => {
      rowOrders?.unobserve(handleUpdateRowDocMap);
    };
  }, [handleUpdateRowDocMap, rowOrders]);

  if (!rowDocMap || !viewId) {
    return null;
  }

  return (
    <div className={'flex w-full flex-1 justify-center'}>
      <Suspense fallback={<ComponentLoading />}>
        <DatabaseContextProvider
          isDatabaseRowPage={!!rowId}
          navigateToRow={onOpenRow}
          iidIndex={iidIndex}
          viewId={viewId}
          databaseDoc={doc}
          rowDocMap={rowDocMap}
          readOnly={true}
          loadView={loadView}
          navigateToView={navigateToView}
          loadViewMeta={loadViewMeta}
          getViewRowsMap={getViewRowsMap}
        >
          {rowId ? (
            <DatabaseRow rowId={rowId} />
          ) : (
            <div className="appflowy-database relative flex w-full flex-1 select-text flex-col overflow-y-hidden">
              <DatabaseViews
                visibleViewIds={visibleViewIds}
                iidIndex={iidIndex}
                viewName={iidName}
                onChangeView={onChangeView}
                viewId={viewId}
                hideConditions={true}
              />
            </div>
          )}
        </DatabaseContextProvider>
      </Suspense>
    </div>
  );
}

export default Database;
