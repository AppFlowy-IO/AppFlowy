import { ViewLayout } from '@/application/collab.type';
import { useViewLayout } from '@/application/folder-yjs';
import { IdProvider } from '@/components/_shared/context-provider/IdProvider';
import React, { lazy, useMemo } from 'react';
import { useParams } from 'react-router-dom';
import DocumentPage from '@/pages/DocumentPage';

const DatabasePage = lazy(() => import('./DatabasePage'));

function ProductPage() {
  const { workspaceId, objectId } = useParams();
  const type = useViewLayout();

  const PageComponent = useMemo(() => {
    switch (type) {
      case ViewLayout.Document:
        return DocumentPage;
      case ViewLayout.Grid:
      case ViewLayout.Board:
      case ViewLayout.Calendar:
        return DatabasePage;
      default:
        return null;
    }
  }, [type]);

  if (!workspaceId || !objectId) return null;

  return (
    <IdProvider workspaceId={workspaceId} objectId={objectId}>
      {PageComponent && <PageComponent />}
    </IdProvider>
  );
}

export default ProductPage;
