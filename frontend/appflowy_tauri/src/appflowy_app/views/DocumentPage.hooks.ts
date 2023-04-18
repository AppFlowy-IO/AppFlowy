import { useEffect, useRef, useState } from 'react';
import {
  DocumentEventGetDocument,
  DocumentVersionPB,
  OpenDocumentPayloadPB,
} from '../../services/backend/events/flowy-document';
import { useParams } from 'react-router-dom';
import { DocumentData } from '../interfaces/document';
import { DocumentController } from '$app/stores/effects/document/document_controller';


export const useDocument = () => {
  const params = useParams();
  const [ documentId, setDocumentId ] = useState<string>();
  const [ documentData, setDocumentData ] = useState<DocumentData>();
  const [ controller, setController ] = useState<DocumentController | null>(null);

  useEffect(() => {
    void (async () => {
      if (!params?.id) return;
      const c = new DocumentController(params.id);
      setController(c);
      try {
        const res = await c.open();
        console.log(res)
        if (!res) return;
        setDocumentData(res);
        setDocumentId(params.id);
      } catch (e) {
        console.log(e)
      }

    })();
    return () => {
      console.log('==== leave ====', params?.id)
    }
  }, [params.id]);
  return { documentId, documentData, controller };
};
