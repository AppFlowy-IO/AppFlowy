import React from 'react';
import { useParams } from 'react-router-dom';
import { Document } from '$app/components/document';

function DocumentPage() {
  const params = useParams();

  const documentId = params.id;

  if (!documentId) return null;
  return (
    <div className={'flex w-full justify-center'}>
      <div className={'max-w-screen w-[964px] min-w-0'}>
        <Document id={documentId} />
      </div>
    </div>
  );
}

export default DocumentPage;
