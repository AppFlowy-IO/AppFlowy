import { useParams } from 'react-router-dom';
import Document from '$app/components/document';

export const DocumentPage = () => {
  const params = useParams();

  const documentId = params.id;

  if (!documentId) return null;

  return <Document documentId={documentId} />;
};
