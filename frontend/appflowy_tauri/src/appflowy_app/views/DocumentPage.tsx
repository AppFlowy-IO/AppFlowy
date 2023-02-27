import { useParams } from 'react-router-dom';
import { useEffect } from 'react';
import { useDocument } from './DocumentPage.hooks';

export const DocumentPage = () => {
  const params = useParams();
  const { loadDocument } = useDocument();
  useEffect(() => {
    void (async () => {
      if (!params?.id) return;
      const content: any = await loadDocument(params.id);
      console.log(content);
    })();
  }, [params]);

  return <div className={'p-8'}>Document Page ID: {params.id}</div>;
};
