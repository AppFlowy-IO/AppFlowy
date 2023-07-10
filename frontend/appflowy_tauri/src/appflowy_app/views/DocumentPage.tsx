import { useDocument } from './DocumentPage.hooks';
import Root from '../components/document/Root';
import { DocumentControllerContext } from '../stores/effects/document/document_controller';

export const DocumentPage = () => {
  const { documentId, documentData, controller } = useDocument();

  if (!documentId || !documentData || !controller) return null;
  return (
    <DocumentControllerContext.Provider value={controller}>
      <Root documentData={documentData} />
    </DocumentControllerContext.Provider>
  );
};
