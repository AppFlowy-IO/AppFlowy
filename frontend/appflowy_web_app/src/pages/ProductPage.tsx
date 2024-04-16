import { CollabType } from '@/application/collab.type';
import { IdProvider } from '@/components/_shared/context-provider/IdProvider';
import React, { useMemo } from 'react';
import { useParams } from 'react-router-dom';
import DocumentPage from '@/pages/DocumentPage';

enum URL_COLLAB_TYPE {
  DOCUMENT = 'document',
  DATABASE = 'database',
}

const collabTypeMap: Record<string, CollabType> = {
  [URL_COLLAB_TYPE.DOCUMENT]: CollabType.Document,
  [URL_COLLAB_TYPE.DATABASE]: CollabType.Database,
};

function ProductPage() {
  const { workspaceId, collabType, objectId } = useParams();

  const PageComponent = useMemo(() => {
    switch (collabType) {
      case URL_COLLAB_TYPE.DOCUMENT:
        return DocumentPage;
      default:
        return null;
    }
  }, [collabType]);

  if (!workspaceId || !collabType || !objectId) return null;

  return (
    <IdProvider workspaceId={workspaceId} objectId={objectId} collabType={collabTypeMap[collabType]}>
      {PageComponent && <PageComponent />}
    </IdProvider>
  );
}

export default ProductPage;
