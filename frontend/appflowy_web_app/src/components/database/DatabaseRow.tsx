import { YDoc, YjsEditorKey } from '@/application/collab.type';
import { useId } from '@/components/_shared/context-provider/IdProvider';
import { AFConfigContext } from '@/components/app/AppConfig';
import { DatabaseRowProperties, DatabaseRowSubDocument } from '@/components/database/components/database-row';
import DatabaseRowHeader from '@/components/database/components/header/DatabaseRowHeader';
import { DatabaseContextProvider } from '@/components/database/DatabaseContext';
import { Log } from '@/utils/log';
import { Divider } from '@mui/material';
import CircularProgress from '@mui/material/CircularProgress';
import React, { useCallback, useContext, useEffect, useState } from 'react';
import RecordNotFound from 'src/components/_shared/not-found/RecordNotFound';
import * as Y from 'yjs';

function DatabaseRow({ rowId }: { rowId: string }) {
  const { objectId, workspaceId } = useId() || {};
  const [doc, setDoc] = useState<YDoc | null>(null);
  const [rows, setRows] = useState<Y.Map<YDoc> | null>(null); // Map<rowId, YDoc
  const databaseService = useContext(AFConfigContext)?.service?.databaseService;
  const [notFound, setNotFound] = useState<boolean>(false);
  const handleOpenDatabaseRow = useCallback(async () => {
    if (!databaseService || !workspaceId || !objectId) return;

    try {
      setDoc(null);
      const { databaseDoc, rows } = await databaseService.openDatabase(workspaceId, objectId, [rowId]);

      console.log('database', databaseDoc.getMap(YjsEditorKey.data_section).toJSON());
      console.log('row', rows.get(rowId)?.getMap(YjsEditorKey.data_section).toJSON());

      const row = rows.get(rowId);

      if (!row) {
        setNotFound(true);
        return;
      }

      setDoc(databaseDoc);
      setRows(rows);
    } catch (e) {
      Log.error(e);
      setNotFound(true);
    }
  }, [databaseService, workspaceId, objectId, rowId]);

  useEffect(() => {
    setNotFound(false);
    void handleOpenDatabaseRow();
  }, [handleOpenDatabaseRow]);

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
    <div className={'flex w-full flex-col items-center'}>
      <div className={'max-w-screen relative flex w-[964px] min-w-0 flex-col gap-4'}>
        <DatabaseContextProvider viewId={objectId} doc={doc} rowDocMap={rows} readOnly={true}>
          <DatabaseRowHeader rowId={rowId} />

          <div className={'flex flex-1 flex-col gap-4'}>
            <DatabaseRowProperties rowId={rowId} />
            <Divider className={'mx-16 max-md:mx-4'} />
            <DatabaseRowSubDocument rowId={rowId} />
          </div>
        </DatabaseContextProvider>
      </div>
    </div>
  );
}

export default DatabaseRow;
