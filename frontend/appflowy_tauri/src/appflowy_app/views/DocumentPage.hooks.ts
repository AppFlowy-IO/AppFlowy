import { useCallback, useEffect, useState } from 'react';
import { useParams } from 'react-router-dom';
import { DocumentData } from '../interfaces/document';
import { DocumentController } from '$app/stores/effects/document/document_controller';
import { useAppDispatch } from '../stores/store';
import { Log } from '../utils/log';
import { documentActions } from '../stores/reducers/document/slice';
import { BlockEventPayloadPB } from '@/services/backend/models/flowy-document2';

export const useDocument = () => {
  const params = useParams();
  const [documentId, setDocumentId] = useState<string>();
  const [documentData, setDocumentData] = useState<DocumentData>();
  const [controller, setController] = useState<DocumentController | null>(null);
  const dispatch = useAppDispatch();

  const onDocumentChange = useCallback((props: { isRemote: boolean; data: BlockEventPayloadPB }) => {
    dispatch(documentActions.onDataChange(props));
  }, []);

  useEffect(() => {
    let documentController: DocumentController | null = null;
    void (async () => {
      if (!params?.id) return;
      Log.debug('open document', params.id);
      documentController = new DocumentController(params.id, onDocumentChange);
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

    const closeDocument = () => {
      if (documentController) {
        void documentController.dispose();
      }
      Log.debug('close document', params.id);
    };

    return closeDocument;
  }, [params.id]);

  return { documentId, documentData, controller };
};
