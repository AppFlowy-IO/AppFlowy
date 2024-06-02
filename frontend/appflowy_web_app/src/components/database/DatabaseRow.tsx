import { YDoc, YjsDatabaseKey, YjsEditorKey } from '@/application/collab.type';
import { DatabaseContextState } from '@/application/database-yjs';
import { useId } from '@/components/_shared/context-provider/IdProvider';
import ComponentLoading from '@/components/_shared/progress/ComponentLoading';
import { AFConfigContext } from '@/components/app/AppConfig';
import { DatabaseRowProperties, DatabaseRowSubDocument } from '@/components/database/components/database-row';
import DatabaseRowHeader from '@/components/database/components/header/DatabaseRowHeader';
import { DatabaseContextProvider } from '@/components/database/DatabaseContext';
import { Log } from '@/utils/log';
import { Divider } from '@mui/material';
import CircularProgress from '@mui/material/CircularProgress';
import React, { Suspense, useCallback, useContext, useEffect, useState } from 'react';
import RecordNotFound from 'src/components/_shared/not-found/RecordNotFound';

function DatabaseRow({ rowId }: { rowId: string }) {
  const { objectId, workspaceId } = useId() || {};
  const [doc, setDoc] = useState<YDoc | null>(null);
  const [rows, setRows] = useState<DatabaseContextState['rowDocMap'] | null>(null); // Map<rowId, YDoc
  const databaseService = useContext(AFConfigContext)?.service?.databaseService;
  const [notFound, setNotFound] = useState<boolean>(false);

  const handleOpenDatabaseRow = useCallback(async () => {
    if (!databaseService || !workspaceId || !objectId) return;

    try {
      setDoc(null);
      const { databaseDoc, rows } = await databaseService.openDatabase(workspaceId, objectId, [rowId]);

      setDoc(databaseDoc);
      setRows(rows);
    } catch (e) {
      Log.error(e);
      setNotFound(true);
    }
  }, [databaseService, workspaceId, objectId, rowId]);
  const databaseId = doc?.getMap(YjsEditorKey.data_section).get(YjsEditorKey.database)?.get(YjsDatabaseKey.id) as string;

  useEffect(() => {
    setNotFound(false);
    void handleOpenDatabaseRow();
  }, [handleOpenDatabaseRow]);

  useEffect(() => {
    if (!databaseId || !databaseService) return;
    return () => {
      void databaseService.closeDatabase(databaseId);
    };
  }, [databaseService, databaseId]);

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
    <div className={'flex w-full justify-center'}>
      <div className={'max-w-screen w-[964px] min-w-0'}>
        <div className={' relative flex  flex-col gap-4'}>
          <DatabaseContextProvider
            isDatabaseRowPage={true}
            viewId={objectId}
            databaseDoc={doc}
            rowDocMap={rows}
            readOnly={true}
          >
            <DatabaseRowHeader rowId={rowId} />

            <div className={'flex flex-1 flex-col gap-4'}>
              <Suspense>
                <DatabaseRowProperties rowId={rowId} />
              </Suspense>
              <Divider className={'mx-16 max-md:mx-4'} />
              <Suspense fallback={<ComponentLoading />}>
                <DatabaseRowSubDocument rowId={rowId} />
              </Suspense>
            </div>
          </DatabaseContextProvider>
        </div>
      </div>
    </div>
  );
}

export default DatabaseRow;
