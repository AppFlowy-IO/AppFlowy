import { AFConfigContext } from '@/components/app/AppConfig';
import CollaborativeEditor from '@/components/editor/CollaborativeEditor';
import { EditorContextProvider } from '@/components/editor/EditorContext';
import { CircularProgress } from '@mui/material';
import React, { useCallback, useContext, useEffect, useState } from 'react';
import * as Y from 'yjs';
import './editor.scss';

export const Editor = ({
  workspaceId,
  documentId,
  readOnly,
}: {
  documentId: string;
  workspaceId: string;
  readOnly: boolean;
}) => {
  const [doc, setDoc] = useState<Y.Doc>();

  const documentService = useContext(AFConfigContext)?.service?.documentService;

  const handleOpenDocument = useCallback(async () => {
    if (!documentService) return;
    const doc = await documentService.openDocument(workspaceId, documentId);

    setDoc(doc);
  }, [documentService, workspaceId, documentId]);

  useEffect(() => {
    void handleOpenDocument();
  }, [handleOpenDocument]);

  if (!doc) {
    return (
      <div className={'justify-content flex h-full w-full items-center'}>
        <CircularProgress />
      </div>
    );
  }

  return (
    <EditorContextProvider readOnly={readOnly}>
      <CollaborativeEditor doc={doc} />
    </EditorContextProvider>
  );
};

export default Editor;
