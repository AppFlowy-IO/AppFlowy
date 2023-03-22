import { useParams } from 'react-router-dom';

import { useEffect, useState } from 'react';
import { Grid } from '../components/grid/Grid/Grid';

export const GridPage = () => {
  const params = useParams();
  const [viewId, setViewId] = useState('');
  useEffect(() => {
    if (params?.id?.length) {
      setViewId(params.id);
      // setDatabaseId('testDb');
    }
  }, [params]);

  return (
    <div className='flex h-full flex-col gap-8 px-8 pt-8'>
      <h1 className='text-4xl font-bold'>Grid: {viewId}</h1>
      {viewId?.length && <Grid viewId={viewId} />}
    </div>
  );
};
