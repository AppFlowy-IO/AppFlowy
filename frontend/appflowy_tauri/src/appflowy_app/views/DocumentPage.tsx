import React from 'react';
import { useParams } from 'react-router-dom';
import { Document } from '$app/components/document';

function DocumentPage() {
  const params = useParams();

  const documentId = params.id;

  if (!documentId) return null;
  return <Document id={documentId} />;
}

export default DocumentPage;
