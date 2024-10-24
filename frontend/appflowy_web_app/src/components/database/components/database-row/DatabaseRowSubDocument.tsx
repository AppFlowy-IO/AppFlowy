import { YDoc } from '@/application/types';
import { DatabaseContext, useRowMetaSelector } from '@/application/database-yjs';
import EditorSkeleton from '@/components/_shared/skeleton/EditorSkeleton';
import { Editor } from '@/components/editor';
import React, { useCallback, useContext, useEffect, useState } from 'react';

export function DatabaseRowSubDocument ({ rowId }: { rowId: string }) {
  const meta = useRowMetaSelector(rowId);
  const documentId = meta?.documentId;
  const loadView = useContext(DatabaseContext)?.loadView;
  const createRowDoc = useContext(DatabaseContext)?.createRowDoc;
  const navigateToView = useContext(DatabaseContext)?.navigateToView;
  const loadViewMeta = useContext(DatabaseContext)?.loadViewMeta;

  const [loading, setLoading] = useState(true);
  const [doc, setDoc] = useState<YDoc | null>(null);

  const handleOpenDocument = useCallback(async () => {
    if (!loadView || !documentId) return;
    try {
      setDoc(null);
      const doc = await loadView(documentId, true);

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
      <EditorSkeleton />
    );
  }

  if (!doc || !documentId) return null;
  return (
    <Editor
      viewId={documentId}
      doc={doc}
      loadViewMeta={loadViewMeta}
      navigateToView={navigateToView}
      createRowDoc={createRowDoc}
      readOnly={true}
      loadView={loadView}
    />
  );
}

export default DatabaseRowSubDocument;
