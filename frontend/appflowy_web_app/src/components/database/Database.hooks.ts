import { YDoc, YjsEditorKey } from '@/application/collab.type';
import { DatabaseContextState } from '@/application/database-yjs';
import { AFConfigContext } from '@/components/app/AppConfig';
import { Log } from '@/utils/log';
import { useCallback, useContext, useEffect, useState } from 'react';

export function useGetDatabaseId(iidIndex: string) {
  const [databaseId, setDatabaseId] = useState<string>();
  const databaseService = useContext(AFConfigContext)?.service?.databaseService;

  const loadDatabaseId = useCallback(async () => {
    if (!databaseService) return;
    const databases = await databaseService.getWorkspaceDatabases();

    console.log('databses', databases);
    const id = databases.find((item) => item.views.includes(iidIndex))?.database_id;

    if (!id) return;
    setDatabaseId(id);
  }, [iidIndex, databaseService]);

  useEffect(() => {
    void loadDatabaseId();
  }, [loadDatabaseId]);
  return databaseId;
}

export function useGetDatabaseDispatch() {
  const databaseService = useContext(AFConfigContext)?.service?.databaseService;
  const onOpenDatabase = useCallback(
    async ({ databaseId, rowIds }: { databaseId: string; rowIds?: string[] }) => {
      if (!databaseService) return Promise.reject();
      return databaseService.openDatabase(databaseId, rowIds);
    },
    [databaseService]
  );

  const onCloseDatabase = useCallback(
    (databaseId: string) => {
      if (!databaseService) return;
      void databaseService.closeDatabase(databaseId);
    },
    [databaseService]
  );

  return {
    onOpenDatabase,
    onCloseDatabase,
  };
}

export function useLoadDatabase({ databaseId, rowIds }: { databaseId?: string; rowIds?: string[] }) {
  const [doc, setDoc] = useState<YDoc | null>(null);
  const [rows, setRows] = useState<DatabaseContextState['rowDocMap'] | null>(null); // Map<rowId, YDoc
  const [notFound, setNotFound] = useState<boolean>(false);
  const { onOpenDatabase, onCloseDatabase } = useGetDatabaseDispatch();

  const handleOpenDatabase = useCallback(
    async (databaseId: string, rowIds?: string[]) => {
      try {
        setDoc(null);
        const { databaseDoc, rows } = await onOpenDatabase({
          databaseId,
          rowIds,
        });

        console.log('databaseDoc', databaseDoc.getMap(YjsEditorKey.data_section).toJSON());
        console.log('rows', rows);

        setDoc(databaseDoc);
        setRows(rows);
      } catch (e) {
        Log.error(e);
        setNotFound(true);
      }
    },
    [onOpenDatabase]
  );

  useEffect(() => {
    if (!databaseId) return;
    void handleOpenDatabase(databaseId, rowIds);
    return () => {
      onCloseDatabase(databaseId);
    };
  }, [handleOpenDatabase, databaseId, rowIds, onCloseDatabase]);

  return { doc, rows, notFound };
}
