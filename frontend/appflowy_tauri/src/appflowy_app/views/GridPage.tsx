import { useParams } from 'react-router-dom';

import { useEffect, useState } from 'react';
import { Grid } from '../components/grid/Grid/Grid';

export const GridPage = () => {
  const params = useParams();
  const [viewId, setViewId] = useState('');

  useEffect(() => {
    if (params?.id?.length) {
      setViewId(params.id);
    }
  }, [params]);

  return (
    <div className='flex h-full flex-col gap-8 px-8 pt-8'>
      {viewId?.length && <Grid viewId={viewId} />}
    </div>
  );
};
