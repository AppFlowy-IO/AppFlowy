import { useParams } from 'react-router-dom';
import { useEffect } from 'react';

export const DocumentPage = () => {
  const params = useParams();

  useEffect(() => {
    console.log('params: ', params);
  }, [params]);

  return <div className={'p-8'}>Page ID: {params.id}</div>;
};
