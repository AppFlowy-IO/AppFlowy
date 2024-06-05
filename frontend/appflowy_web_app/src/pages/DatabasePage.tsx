import { useId } from '@/components/_shared/context-provider/IdProvider';
import { DatabaseHeader } from '@/components/database/components/header';
import { useGetDatabaseId, useLoadDatabase } from '@/components/database/Database.hooks';
import { DatabaseContextProvider } from '@/components/database/DatabaseContext';
import CircularProgress from '@mui/material/CircularProgress';
import React, { useCallback, useMemo } from 'react';
import { useSearchParams } from 'react-router-dom';
import DatabaseRow from '@/components/database/DatabaseRow';
import Database from '@/components/database/Database';
import RecordNotFound from 'src/components/_shared/not-found/RecordNotFound';

function DatabasePage() {
  const { objectId } = useId() || {};
  const [search, setSearch] = useSearchParams();
  const rowId = search.get('r');

  const viewId = search.get('v') || undefined;
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

  const databaseId = useGetDatabaseId(objectId);
  const rowIds = useMemo(() => (rowId ? [rowId] : undefined), [rowId]);

  const { doc, rows, notFound } = useLoadDatabase({
    databaseId,
    rowIds,
  });

  if (notFound || !objectId) {
    return <RecordNotFound open={notFound} />;
  }

  if (!rows || !doc) {
    return (
      <div className={'flex h-full w-full items-center justify-center'}>
        <CircularProgress />
      </div>
    );
  }

  return (
    <DatabaseContextProvider
      isDatabaseRowPage={!!rowId}
      navigateToRow={handleNavigateToRow}
      viewId={viewId || objectId}
      databaseDoc={doc}
      rowDocMap={rows}
      readOnly={true}
    >
      {rowId ? (
        <DatabaseRow rowId={rowId} />
      ) : (
        <div className={'relative flex h-full w-full flex-col'}>
          <DatabaseHeader viewId={objectId} />
          <Database iidIndex={objectId} viewId={viewId || objectId} onNavigateToView={handleChangeView} />
        </div>
      )}
    </DatabaseContextProvider>
  );
}

export default DatabasePage;
