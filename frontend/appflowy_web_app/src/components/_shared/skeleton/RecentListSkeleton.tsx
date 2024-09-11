import React from 'react';
import { Box, Skeleton } from '@mui/material';

const RecentListSkeleton = ({ rows = 5 }) => {
  return (
    <Box sx={{ width: '100%', maxWidth: 360, bgcolor: 'background.paper' }}>
      {[...Array(rows)].map((_, index) => (
        <Box key={index} sx={{ display: 'flex', alignItems: 'center', my: 1, mx: 2, gap: 2 }}>
          <Skeleton variant="circular" width={20} height={20} />
          <Skeleton variant="text" className={'flex-1'} />
        </Box>
      ))}
    </Box>
  );
};

export default RecentListSkeleton;