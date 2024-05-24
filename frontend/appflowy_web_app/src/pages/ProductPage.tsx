import { IdProvider } from '@/components/_shared/context-provider/IdProvider';
import React, { lazy, useMemo } from 'react';
import { useParams } from 'react-router-dom';
import DocumentPage from '@/pages/DocumentPage';

const DatabasePage = lazy(() => import('./DatabasePage'));

enum URL_COLLAB_TYPE {
  DOCUMENT = 'document',
  GRID = 'grid',
  BOARD = 'board',
  CALENDAR = 'calendar',
}

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

  if (!workspaceId || !type || !objectId) return null;

  return (
    <IdProvider workspaceId={workspaceId} objectId={objectId}>
      {PageComponent && <PageComponent />}
    </IdProvider>
  );
}

export default ProductPage;
