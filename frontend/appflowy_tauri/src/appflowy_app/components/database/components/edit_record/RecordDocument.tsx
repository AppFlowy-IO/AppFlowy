import React from 'react';
import Document from '$app/components/document';
import { ContainerType } from '$app/hooks/document.hooks';

interface Props {
  documentId: string;
  getDocumentTitle?: () => React.ReactNode;
}

function RecordDocument({ documentId, getDocumentTitle }: Props) {
  return (
    <div className={'-ml-[72px] h-full min-h-[200px] w-[calc(100%+144px)]'}>
      <Document getDocumentTitle={getDocumentTitle} containerType={ContainerType.EditRecord} documentId={documentId} />
    </div>
  );
}

export default React.memo(RecordDocument);
