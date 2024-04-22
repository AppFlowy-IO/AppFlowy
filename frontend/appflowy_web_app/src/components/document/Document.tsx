import { useId } from '@/components/_shared/context-provider/IdProvider';
import { Editor } from '@/components/editor';
import React from 'react';

export const Document = () => {
  const { objectId: documentId, workspaceId } = useId() || {};

  if (!documentId || !workspaceId) return null;

  return (
    <div className={'relative w-full'}>
      <div className={'flex w-full justify-center'}>
        <div className={'max-w-screen mt-6 w-[964px] min-w-0'}>
          <Editor readOnly={true} documentId={documentId} workspaceId={workspaceId} />
        </div>
      </div>
    </div>
  );
};
