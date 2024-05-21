import { CollabType } from '@/application/collab.type';
import { IdProvider } from '@/components/_shared/context-provider/IdProvider';
import DatabasePage from '@/pages/DatabasePage';
import React, { useMemo } from 'react';
import { useParams } from 'react-router-dom';
import DocumentPage from '@/pages/DocumentPage';

enum URL_COLLAB_TYPE {
  DOCUMENT = 'document',
  GRID = 'grid',
  BOARD = 'board',
  CALENDAR = 'calendar',
}

const collabTypeMap: Record<string, CollabType> = {
  [URL_COLLAB_TYPE.DOCUMENT]: CollabType.Document,
  [URL_COLLAB_TYPE.GRID]: CollabType.WorkspaceDatabase,
  [URL_COLLAB_TYPE.BOARD]: CollabType.WorkspaceDatabase,
  [URL_COLLAB_TYPE.CALENDAR]: CollabType.WorkspaceDatabase,
};

function ProductPage() {
  const { workspaceId, type, objectId } = useParams();
  const PageComponent = useMemo(() => {
    switch (type) {
      case URL_COLLAB_TYPE.DOCUMENT:
        return DocumentPage;
      case URL_COLLAB_TYPE.GRID:
      case URL_COLLAB_TYPE.BOARD:
      case URL_COLLAB_TYPE.CALENDAR:
        return DatabasePage;
      default:
        return null;
    }
  }, [type]);

  console.log(workspaceId, type, objectId);
  if (!workspaceId || !type || !objectId) return null;

  return (
    <IdProvider workspaceId={workspaceId} objectId={objectId} collabType={collabTypeMap[type]}>
      {PageComponent && <PageComponent />}
    </IdProvider>
  );
}

export default ProductPage;
