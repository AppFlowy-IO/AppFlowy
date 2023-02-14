import {
  DocumentEventGetDocument,
  DocumentVersionPB,
  OpenDocumentPayloadPB,
} from '../../services/backend/events/flowy-document';

export const useDocument = () => {
  const loadDocument = async (id: string): Promise<any> => {
    const getDocumentResult = await DocumentEventGetDocument(
      OpenDocumentPayloadPB.fromObject({
        document_id: id,
        version: DocumentVersionPB.V1,
      })
    );

    if (getDocumentResult.ok) {
      const pb = getDocumentResult.val;
      return JSON.parse(pb.content);
    } else {
      throw new Error('get document error');
    }
  };
  return { loadDocument };
};
