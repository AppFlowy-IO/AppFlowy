import { useEffect, useRef, useState } from 'react';
import {
  DocumentEventGetDocument,
  DocumentVersionPB,
  OpenDocumentPayloadPB,
} from '../../services/backend/events/flowy-document';
import { useParams } from 'react-router-dom';
import { DocumentData } from '../interfaces/document';
import { DocumentController } from '$app/stores/effects/document/document_controller';
import { useAppDispatch } from '../stores/store';

export const useDocument = () => {
  const params = useParams();
  const [documentId, setDocumentId] = useState<string>();
  const [documentData, setDocumentData] = useState<DocumentData>();
  const [controller, setController] = useState<DocumentController | null>(null);
  const dispatch = useAppDispatch();

  useEffect(() => {
    let documentController: DocumentController | null = null;
    void (async () => {
      if (!params?.id) return;
      console.log('==== enter ====', params?.id);
      documentController = new DocumentController(params.id, dispatch);
      setController(documentController);
      try {
        const res = await documentController.open();
        if (!res) return;
        setDocumentData(res);
        setDocumentId(params.id);
      } catch (e) {
        console.error(e);
      }
    })();
    return () => {
      void (async () => {
        if (documentController) {
          await documentController.dispose();
        }
        console.log('==== leave ====', params?.id);
      })();
    };
  }, [params.id]);
  return { documentId, documentData, controller };
};
