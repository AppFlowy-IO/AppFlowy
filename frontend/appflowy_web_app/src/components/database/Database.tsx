import { YDatabase, YDoc, YjsDatabaseKey, YjsEditorKey } from '@/application/collab.type';
import { ViewMeta } from '@/application/db/tables/view_metas';
import ComponentLoading from '@/components/_shared/progress/ComponentLoading';
import DatabaseRow from '@/components/database/DatabaseRow';
import DatabaseViews from '@/components/database/DatabaseViews';
import { ViewMetaPreview, ViewMetaProps } from '@/components/view-meta/ViewMetaPreview';
import React, { Suspense, useCallback, useEffect, useMemo, useState } from 'react';
import { useSearchParams } from 'react-router-dom';
import * as Y from 'yjs';
import { DatabaseContextProvider } from './DatabaseContext';

export interface Database2Props extends ViewMetaProps {
  doc: YDoc;
  isDark?: boolean;
  getViewRowsMap?: (viewId: string, rowIds: string[]) => Promise<{ rows: Y.Map<YDoc>; destroy: () => void }>;
  loadView?: (viewId: string) => Promise<YDoc>;
  navigateToView?: (viewId: string) => Promise<void>;
  loadViewMeta?: (viewId: string) => Promise<ViewMeta>;
}

function Database({ doc, isDark, getViewRowsMap, navigateToView, loadViewMeta, loadView, ...viewMeta }: Database2Props) {
  const [search, setSearch] = useSearchParams();

  const viewId = search.get('v') || viewMeta.viewId;

  const rowIds = useMemo(() => {
    if (!viewId) return [];
    const database = doc.getMap(YjsEditorKey.data_section).get(YjsEditorKey.database) as YDatabase;
    const rows = database.get(YjsDatabaseKey.views).get(viewId).get(YjsDatabaseKey.row_orders);

    return rows.toArray().map((row) => row.get(YjsDatabaseKey.id));
  }, [doc, viewId]);

  const iidIndex = useMemo(() => {
    const database = doc.getMap(YjsEditorKey.data_section).get(YjsEditorKey.database) as YDatabase;

    return database.get(YjsDatabaseKey.metas).get(YjsDatabaseKey.iid);
  }, [doc]);

  const [rowDocMap, setRowDocMap] = useState<Y.Map<YDoc> | null>(null);

  useEffect(() => {
    if (!getViewRowsMap || !rowIds.length || !iidIndex) return;

    void (async () => {
      const { rows, destroy } = await getViewRowsMap(iidIndex, rowIds);

      setRowDocMap(rows);
      return destroy;
    })();
  }, [getViewRowsMap, rowIds, iidIndex]);

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
    <div className={'flex w-full justify-center'}>
      <Suspense fallback={<ComponentLoading />}>
        <DatabaseContextProvider
          isDark={isDark}
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
              {viewMeta && <ViewMetaPreview {...viewMeta} />}

              <div className='appflowy-database relative flex w-full flex-1 select-text flex-col overflow-y-hidden'>
                <DatabaseViews iidIndex={iidIndex} onChangeView={handleChangeView} viewId={viewId} />
              </div>
            </div>
          )}
        </DatabaseContextProvider>
      </Suspense>
    </div>
  );
}

export default Database;
