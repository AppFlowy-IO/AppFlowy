import { YDoc } from '@/application/types';
import { useDatabaseContext, useReadOnly, useRowMetaSelector } from '@/application/database-yjs';
import EditorSkeleton from '@/components/_shared/skeleton/EditorSkeleton';
import { Editor } from '@/components/editor';
import React, { useCallback, useEffect, useState } from 'react';

export function DatabaseRowSubDocument ({ rowId }: { rowId: string }) {
  const meta = useRowMetaSelector(rowId);
  const readOnly = useReadOnly();
  const documentId = meta?.documentId;
  const context = useDatabaseContext();
  const loadView = context.loadView;
  const createRowDoc = context.createRowDoc;
  const navigateToView = context.navigateToView;
  const loadViewMeta = context.loadViewMeta;

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
      readOnly={readOnly}
      loadView={loadView}
    />
  );
}

export default DatabaseRowSubDocument;
