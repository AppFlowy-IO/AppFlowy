import Skeleton from '@mui/material/Skeleton';
import React from 'react';

function DocumentSkeleton () {
  return (
    <div
      style={{
        minHeight: '50vh',
      }}
      className={'mx-16 w-[964px] min-w-0 max-w-full max-xl:px-8 max-lg:px-6'}
    >
      <Skeleton variant="rectangular" width={'100%'} height={'100%'} />
    </div>
  );
}

export default DocumentSkeleton;
