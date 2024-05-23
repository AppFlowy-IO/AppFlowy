import { YDoc } from '@/application/collab.type';
import { useId } from '@/components/_shared/context-provider/IdProvider';
import { AFConfigContext } from '@/components/app/AppConfig';
import { DocumentHeader } from '@/components/document/document_header';
import { Editor } from '@/components/editor';
import { Log } from '@/utils/log';
import React, { useCallback, useContext, useEffect, useState } from 'react';
import RecordNotFound from 'src/components/_shared/not-found/RecordNotFound';

export const Document = () => {
  const { objectId: documentId, workspaceId } = useId() || {};
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

  if (!documentId) return null;

  return (
    <>
      {doc && (
        <div className={'relative w-full'}>
          <DocumentHeader doc={doc} viewId={documentId} />
          <div className={'flex w-full justify-center'}>
            <div className={'max-w-screen w-[964px] min-w-0'}>
              <Editor doc={doc} readOnly={true} includeRoot={true} />
            </div>
          </div>
        </div>
      )}

      <RecordNotFound open={notFound} workspaceId={workspaceId} />
    </>
  );
};

export default Document;
