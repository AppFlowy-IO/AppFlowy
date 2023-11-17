import React from 'react';
import { ContainerType, ContainerTypeProvider, useDocument } from '$app/hooks/document.hooks';
import { DocumentControllerContext } from '$app/stores/effects/document/document_controller';
import Root from '$app/components/document/Root';

interface Props {
  documentId: string;
  containerType?: ContainerType;
  getDocumentTitle?: () => React.ReactNode;
}
function Document({ documentId, getDocumentTitle, containerType = ContainerType.DocumentPage }: Props) {
  const { documentData, controller } = useDocument(documentId);

  if (!documentId || !documentData || !controller) return null;
  return (
    <ContainerTypeProvider value={containerType}>
      <DocumentControllerContext.Provider value={controller}>
        <Root getDocumentTitle={getDocumentTitle} documentData={documentData} />
      </DocumentControllerContext.Provider>
    </ContainerTypeProvider>
  );
}

export default Document;
