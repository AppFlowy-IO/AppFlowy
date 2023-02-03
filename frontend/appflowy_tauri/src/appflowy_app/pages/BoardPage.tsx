import { useParams } from 'react-router-dom';

export const BoardPage = () => {
  const params = useParams();

  return <div className={'p-8'}>Board Page ID: {params.id}</div>;
};
