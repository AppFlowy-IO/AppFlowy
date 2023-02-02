import { useParams } from 'react-router-dom';
import { useEffect } from 'react';

export const DocumentPage = () => {
  const params = useParams();

  return <div className={'p-8'}>Document Page ID: {params.id}</div>;
};
