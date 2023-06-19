import { DocumentControllerContext } from '$app/stores/effects/document/document_controller';
import { useContext } from 'react';
import { useAppSelector } from '$app/stores/store';

export function useSubscribeDocument() {
  const controller = useContext(DocumentControllerContext);
  const docId = controller.documentId;
  return {
    docId,
    controller,
  };
}

export function useSubscribeDocumentData() {
  const { docId } = useSubscribeDocument();
  const data = useAppSelector((state) => {
    return state.document[docId];
  });
  return data;
}
