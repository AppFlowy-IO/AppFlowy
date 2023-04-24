import { useEffect, useState } from 'react';
import { useParams } from 'react-router-dom';
import { DocumentData } from '../interfaces/document';
import { DocumentController } from '$app/stores/effects/document/document_controller';
import { useAppDispatch } from '../stores/store';
import { Log } from '../utils/log';

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
      Log.debug('open document', params.id);
      documentController = new DocumentController(params.id, dispatch);
      setController(documentController);
      try {
        const res = await documentController.open();
        if (!res) return;
        setDocumentData(res);
        setDocumentId(params.id);
      } catch (e) {
        Log.error(e);
      }
    })();
    return () => {
      void (async () => {
        if (documentController) {
          await documentController.dispose();
        }
        Log.debug('close document', params.id);
      })();
    };
  }, [params.id]);
  return { documentId, documentData, controller };
};
