import { YDoc, YjsEditorKey } from '@/application/collab.type';
import { useId } from '@/components/_shared/context-provider/IdProvider';
import RecordNotFound from '@/components/_shared/not-found/RecordNotFound';
import { AFConfigContext } from '@/components/app/AppConfig';
import DatabaseViews from '@/components/database/DatabaseViews';
import { DatabaseContextProvider } from '@/components/database/DatabaseContext';
import { Log } from '@/utils/log';
import CircularProgress from '@mui/material/CircularProgress';
import React, { memo, useCallback, useContext, useEffect, useState } from 'react';
import { useSearchParams } from 'react-router-dom';
import * as Y from 'yjs';

export const Database = memo((props?: { onNavigateToRow?: (viewId: string, rowId: string) => void }) => {
  const { objectId, workspaceId } = useId() || {};
  const [search, setSearch] = useSearchParams();

  const viewId = search.get('v');
  const [doc, setDoc] = useState<YDoc | null>(null);
  const [rows, setRows] = useState<Y.Map<YDoc> | null>(null); // Map<rowId, YDoc
  const [notFound, setNotFound] = useState<boolean>(false);
  const databaseService = useContext(AFConfigContext)?.service?.databaseService;

  const handleOpenDatabase = useCallback(async () => {
    if (!databaseService || !workspaceId || !objectId) return;

    try {
      setDoc(null);
      const { databaseDoc, rows } = await databaseService.openDatabase(workspaceId, objectId);

      console.log('databaseDoc', databaseDoc.getMap(YjsEditorKey.data_section).toJSON());
      console.log('rows', rows);

      setDoc(databaseDoc);
      setRows(rows);
    } catch (e) {
      Log.error(e);
      setNotFound(true);
    }
  }, [databaseService, workspaceId, objectId]);

  useEffect(() => {
    setNotFound(false);
    void handleOpenDatabase();
  }, [handleOpenDatabase]);

  const handleChangeView = useCallback(
    (viewId: string) => {
      setSearch({ v: viewId });
    },
    [setSearch]
  );

  const navigateToRow = useCallback(
    (rowId: string) => {
      const currentViewId = objectId || viewId;

      if (props?.onNavigateToRow && currentViewId) {
        props.onNavigateToRow(currentViewId, rowId);
        return;
      }

      setSearch({ r: rowId });
    },
    [props, setSearch, viewId, objectId]
  );

  if (notFound || !objectId) {
    return <RecordNotFound open={notFound} workspaceId={workspaceId} />;
  }

  if (!rows || !doc) {
    return (
      <div className={'flex h-full w-full items-center justify-center'}>
        <CircularProgress />
      </div>
    );
  }

  return (
    <div className='appflowy-database relative flex w-full flex-1 select-text flex-col overflow-y-hidden'>
      <DatabaseContextProvider
        navigateToRow={navigateToRow}
        viewId={viewId || objectId}
        doc={doc}
        rowDocMap={rows}
        readOnly={true}
      >
        <DatabaseViews onChangeView={handleChangeView} currentViewId={viewId || objectId} />
      </DatabaseContextProvider>
    </div>
  );
});

export default Database;
