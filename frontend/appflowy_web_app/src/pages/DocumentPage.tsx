import { Editor } from '@/components/editor/Editor';
import React, { useContext, useEffect } from 'react';
import { AFConfigContext } from '@/AppConfig';

function DocumentPage ({ workspaceId, documentId }: {
  documentId: string;
  workspaceId: string;
}) {

  return (
    <div>
      <Editor documentId={documentId} workspaceId={workspaceId} />
    </div>
  );
}

export default DocumentPage;