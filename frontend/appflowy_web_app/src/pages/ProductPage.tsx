import React from 'react';
import { useParams } from 'react-router-dom';
import DocumentPage from '@/pages/DocumentPage';

function ProductPage () {
  const {
    workspaceId,
    collabType,
    objectId,
  } = useParams();

  if (!workspaceId || !collabType || !objectId) return null;

  if (collabType === 'document') {
    return (
      <DocumentPage workspaceId={workspaceId} documentId={objectId} />
    );
  }

  return null;
}

export default ProductPage;