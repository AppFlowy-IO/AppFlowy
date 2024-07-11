import { YDatabase, YDoc, YjsDatabaseKey, YjsEditorKey } from '@/application/collab.type';
import { ViewMeta } from '@/application/db/tables/view_metas';
import ComponentLoading from '@/components/_shared/progress/ComponentLoading';
import DatabaseRow from '@/components/database/DatabaseRow';
import DatabaseViews from '@/components/database/DatabaseViews';
import React, { Suspense, useCallback, useEffect, useState } from 'react';
import * as Y from 'yjs';
import { DatabaseContextProvider } from './DatabaseContext';

export interface Database2Props {
  doc: YDoc;
  getViewRowsMap?: (viewId: string, rowIds?: string[]) => Promise<{ rows: Y.Map<YDoc>; destroy: () => void }>;
  loadView?: (viewId: string) => Promise<YDoc>;
  navigateToView?: (viewId: string) => Promise<void>;
  loadViewMeta?: (viewId: string) => Promise<ViewMeta>;
  viewId: string;
  iidName: string;
  rowId?: string;
  onChangeView: (viewId: string) => void;
  onOpenRow?: (rowId: string) => void;
}

function Database({
  doc,
  getViewRowsMap,
  navigateToView,
  loadViewMeta,
  loadView,
  viewId,
  iidName,
  rowId,
  onChangeView,
  onOpenRow,
}: Database2Props) {
  const database = doc.getMap(YjsEditorKey.data_section).get(YjsEditorKey.database) as YDatabase;

  const iidIndex = database.get(YjsDatabaseKey.metas).get(YjsDatabaseKey.iid);

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
          viewId={viewId}
          databaseDoc={doc}
          rowDocMap={rowDocMap}
          readOnly={true}
          loadView={loadView}
          navigateToView={navigateToView}
          loadViewMeta={loadViewMeta}
        >
          {rowId ? (
            <DatabaseRow rowId={rowId} />
          ) : (
            <div className='appflowy-database relative flex w-full flex-1 select-text flex-col overflow-y-hidden'>
              <DatabaseViews iidIndex={iidIndex} viewName={iidName} onChangeView={onChangeView} viewId={viewId} />
            </div>
          )}
        </DatabaseContextProvider>
      </Suspense>
    </div>
  );
}

export default Database;
