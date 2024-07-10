import { YDatabase, YDoc, YjsDatabaseKey, YjsEditorKey } from '@/application/collab.type';
import { ViewMeta } from '@/application/db/tables/view_metas';
import ComponentLoading from '@/components/_shared/progress/ComponentLoading';
import DatabaseHeader from '@/components/database/components/header/DatabaseHeader';
import DatabaseRow from '@/components/database/DatabaseRow';
import DatabaseViews from '@/components/database/DatabaseViews';
import { ViewMetaProps } from '@/components/view-meta/ViewMetaPreview';
import React, { Suspense, useCallback, useEffect, useState } from 'react';
import { useSearchParams } from 'react-router-dom';
import * as Y from 'yjs';
import { DatabaseContextProvider } from './DatabaseContext';

export interface Database2Props extends ViewMetaProps {
  doc: YDoc;
  getViewRowsMap?: (viewId: string, rowIds?: string[]) => Promise<{ rows: Y.Map<YDoc>; destroy: () => void }>;
  loadView?: (viewId: string) => Promise<YDoc>;
  navigateToView?: (viewId: string) => Promise<void>;
  loadViewMeta?: (viewId: string) => Promise<ViewMeta>;
}

function Database({ doc, getViewRowsMap, navigateToView, loadViewMeta, loadView, ...viewMeta }: Database2Props) {
  const [search, setSearch] = useSearchParams();

  const viewId = search.get('v') || viewMeta.viewId;
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

  const rowId = search.get('r');

  const handleChangeView = useCallback(
    (viewId: string) => {
      setSearch({ v: viewId });
    },
    [setSearch]
  );

  const handleNavigateToRow = useCallback(
    (rowId: string) => {
      setSearch({ r: rowId });
    },
    [setSearch]
  );

  if (!rowDocMap || !viewId) {
    return null;
  }

  return (
    <div
      style={{
        height: 'calc(100vh - 48px)',
      }}
      className={'flex w-full justify-center'}
    >
      <Suspense fallback={<ComponentLoading />}>
        <DatabaseContextProvider
          isDatabaseRowPage={!!rowId}
          navigateToRow={handleNavigateToRow}
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
            <div className={'relative flex h-full w-full flex-col'}>
              {viewMeta && <DatabaseHeader {...viewMeta} />}

              <div className='appflowy-database relative flex w-full flex-1 select-text flex-col overflow-y-hidden'>
                <DatabaseViews
                  iidIndex={iidIndex}
                  viewName={viewMeta.name}
                  onChangeView={handleChangeView}
                  viewId={viewId}
                />
              </div>
            </div>
          )}
        </DatabaseContextProvider>
      </Suspense>
    </div>
  );
}

export default Database;
