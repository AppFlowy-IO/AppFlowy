import { DocumentControllerContext } from '$app/stores/effects/document/document_controller';
import { useContext } from 'react';

export function useSubscribeDocument() {
  const controller = useContext(DocumentControllerContext);
  const docId = controller.documentId;
  return {
    docId,
    controller,
  };
}
