import { useParams } from 'react-router-dom';

export const GridPage = () => {
  const params = useParams();

  return <div className={'p-8'}>Grid Page ID: {params.id}</div>;
};
