import React from 'react';
import { Skeleton, Box } from '@mui/material';

export const BreadcrumbsSkeleton = () => {
  return (
    <Box display="flex" alignItems="center">
      <Skeleton variant="text" width={60} height={20} />
      <Skeleton variant="text" width={20} height={20} sx={{ mx: 1 }} />
      <Skeleton variant="text" width={80} height={20} />
      <Skeleton variant="text" width={20} height={20} sx={{ mx: 1 }} />
      <Skeleton variant="text" width={100} height={20} />
    </Box>
  );
};

export default BreadcrumbsSkeleton;