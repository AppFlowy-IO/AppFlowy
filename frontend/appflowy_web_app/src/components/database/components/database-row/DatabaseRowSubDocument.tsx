import { YDoc } from '@/application/collab.type';
import { useRowMetaSelector } from '@/application/database-yjs';
import { useId } from '@/components/_shared/context-provider/IdProvider';
import { AFConfigContext } from '@/components/app/AppConfig';
import { Editor } from '@/components/editor';
import { Log } from '@/utils/log';
import CircularProgress from '@mui/material/CircularProgress';
import React, { useCallback, useContext, useEffect, useState } from 'react';
import RecordNotFound from '@/components/_shared/not-found/RecordNotFound';

export function DatabaseRowSubDocument({ rowId }: { rowId: string }) {
  const { workspaceId } = useId() || {};
  const documentId = useRowMetaSelector(rowId)?.documentId;

  const [doc, setDoc] = useState<YDoc | null>(null);
  const [notFound, setNotFound] = useState<boolean>(false);

  const documentService = useContext(AFConfigContext)?.service?.documentService;

  const handleOpenDocument = useCallback(async () => {
    if (!documentService || !workspaceId || !documentId) return;
    try {
      setDoc(null);
      const doc = await documentService.openDocument(workspaceId, documentId);

      setDoc(doc);
    } catch (e) {
      Log.error(e);
      setNotFound(true);
    }
  }, [documentService, workspaceId, documentId]);

  useEffect(() => {
    setNotFound(false);
    void handleOpenDocument();
  }, [handleOpenDocument]);

  if (notFound || !documentId) {
    return <RecordNotFound open={notFound} workspaceId={workspaceId} />;
  }

  if (!doc) {
    return (
      <div className={'flex h-full w-full items-center justify-center'}>
        <CircularProgress />
      </div>
    );
  }

  return <Editor doc={doc} readOnly={true} includeRoot={false} />;
}

export default DatabaseRowSubDocument;
