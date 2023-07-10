import { DocumentControllerContext } from '$app/stores/effects/document/document_controller';
import { useContext } from 'react';
import { useAppSelector } from '$app/stores/store';
import { DOCUMENT_NAME } from '$app/constants/document/name';

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
    return state[DOCUMENT_NAME][docId];
  });

  return data;
}
