import { YDoc } from '@/application/types';
import ComponentLoading from '@/components/_shared/progress/ComponentLoading';
import { GlobalCommentProvider } from '@/components/global-comment';
import CollabView from '@/components/publish/CollabView';
import React, { Suspense } from 'react';

function PublishMain ({ doc, isTemplate }: {
  doc?: YDoc;
  isTemplate: boolean;
}) {
  return (
    <>
      <CollabView doc={doc} />
      {doc && !isTemplate && (
        <Suspense fallback={<ComponentLoading />}>
          <GlobalCommentProvider />
        </Suspense>
      )}
    </>
  );
}

export default PublishMain;