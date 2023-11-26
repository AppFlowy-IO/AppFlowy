import { useCallback, useEffect, useState } from 'react';
import { DocumentData } from '../interfaces/document';
import { DocumentController } from '$app/stores/effects/document/document_controller';
import { useAppDispatch } from '../stores/store';
import { Log } from '../utils/log';
import {
  documentActions,
  rangeActions,
  rectSelectionActions,
  slashCommandActions,
} from '$app/stores/reducers/document/slice';
import { BlockEventPayloadPB } from '@/services/backend/models/flowy-document2';

export const useDocument = (documentId?: string) => {
  const [documentData, setDocumentData] = useState<DocumentData>();
  const [controller, setController] = useState<DocumentController | null>(null);
  const dispatch = useAppDispatch();

  const onDocumentChange = useCallback(
    (props: { docId: string; isRemote: boolean; data: BlockEventPayloadPB }) => {
      dispatch(documentActions.onDataChange(props));
    },
    [dispatch]
  );

  const initializeDocument = useCallback(
    (docId: string) => {
      Log.debug('initialize document', docId);
      dispatch(documentActions.initialState(docId));
      dispatch(rangeActions.initialState(docId));
      dispatch(rectSelectionActions.initialState(docId));
      dispatch(slashCommandActions.initialState(docId));
    },
    [dispatch]
  );

  const clearDocument = useCallback(
    (docId: string) => {
      Log.debug('clear document', docId);
      dispatch(documentActions.clear(docId));
      dispatch(rangeActions.clear(docId));
      dispatch(rectSelectionActions.clear(docId));
      dispatch(slashCommandActions.clear(docId));
    },
    [dispatch]
  );

  useEffect(() => {
    let documentController: DocumentController | null = null;

    void (async () => {
      if (!documentId) return;
      documentController = new DocumentController(documentId, onDocumentChange);
      const docId = documentController.documentId;

      Log.debug('open document', documentId);

      initializeDocument(documentController.documentId);

      setController(documentController);
      try {
        const res = await documentController.open();

        if (!res) return;
        dispatch(
          documentActions.create({
            ...res,
            docId,
          })
        );
        setDocumentData(res);
      } catch (e) {
        Log.error(e);
      }
    })();

    return () => {
      if (documentController) {
        void (async () => {
          await documentController.dispose();
          clearDocument(documentController.documentId);
        })();
      }

      Log.debug('close document', documentId);
    };
  }, [clearDocument, dispatch, initializeDocument, onDocumentChange, documentId]);

  return { documentId, documentData, controller };
};
