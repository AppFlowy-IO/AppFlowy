import { AFConfigContext } from '@/AppConfig';
import Editor from '@/components/editor/slate/Editor';
import { CircularProgress } from '@mui/material';
import React, { useContext, useEffect, useState } from 'react';
import * as Y from 'yjs';

function CollaborativeEditor ({ workspaceId, documentId }: {
  documentId: string;
  workspaceId: string;
}) {

  const [doc, setDoc] = useState<Y.Doc>();

  const documentService = useContext(AFConfigContext)?.service?.documentService;

  useEffect(() => {
    if (!documentService) return;
    // Fetch the product data
    documentService.openDocument(workspaceId, documentId).then(doc => {
      setDoc(doc);
    }).catch(e => {
      console.error(e);
    });
  }, [documentId, documentService, workspaceId]);

  if (!doc) {
    return <div className={'h-full w-full flex items-center justify-content'}>
      <CircularProgress />
    </div>;
  }

  return (
    <Editor doc={doc} />
  );
}

export default CollaborativeEditor;