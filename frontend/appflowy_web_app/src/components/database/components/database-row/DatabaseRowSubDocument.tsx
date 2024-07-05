import { YDoc } from '@/application/collab.type';
import { DatabaseContext, useRowMetaSelector } from '@/application/database-yjs';
import { Editor } from '@/components/editor';
import CircularProgress from '@mui/material/CircularProgress';
import React, { useCallback, useContext, useEffect, useState } from 'react';

export function DatabaseRowSubDocument({ rowId }: { rowId: string }) {
  const meta = useRowMetaSelector(rowId);
  const documentId = meta?.documentId;
  const isDark = useContext(DatabaseContext)?.isDark || false;
  const loadView = useContext(DatabaseContext)?.loadView;
  const getViewRowsMap = useContext(DatabaseContext)?.getViewRowsMap;
  const navigateToView = useContext(DatabaseContext)?.navigateToView;
  const loadViewMeta = useContext(DatabaseContext)?.loadViewMeta;

  const [loading, setLoading] = useState(true);
  const [doc, setDoc] = useState<YDoc | null>(null);

  const handleOpenDocument = useCallback(async () => {
    if (!loadView || !documentId) return;
    try {
      setDoc(null);
      const doc = await loadView(documentId);

      console.log('doc', doc);
      setDoc(doc);
    } catch (e) {
      console.error(e);
      // haven't created by client, ignore error and show empty
    }
  }, [loadView, documentId]);

  useEffect(() => {
    setLoading(true);
    void handleOpenDocument().then(() => setLoading(false));
  }, [handleOpenDocument]);

  if (loading) {
    return (
      <div className={'flex h-[260px] w-full items-center justify-center'}>
        <CircularProgress />
      </div>
    );
  }

  if (!doc) return null;

  return (
    <Editor
      isDark={isDark}
      doc={doc}
      loadViewMeta={loadViewMeta}
      navigateToView={navigateToView}
      getViewRowsMap={getViewRowsMap}
      readOnly={true}
      loadView={loadView}
    />
  );
}

export default DatabaseRowSubDocument;
