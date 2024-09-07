import React from 'react';
import { Skeleton, Box } from '@mui/material';
import { ReactComponent as RightIcon } from '@/assets/arrow_right.svg';

export const BreadcrumbsSkeleton = () => {
  return (
    <Box display="flex" alignItems="center" gap={1}>
      <Skeleton variant="circular" width={20} height={20} />
      <Skeleton variant="text" width={60} height={20} />
      <RightIcon className={'h-5 w-5 text-text-caption'} />
      <Skeleton variant="circular" width={20} height={20} />
      <Skeleton variant="text" width={80} height={20} />
      <RightIcon className={'h-5 w-5 text-text-caption'} />
      <Skeleton variant="circular" width={20} height={20} />
      <Skeleton variant="text" width={100} height={20} />
    </Box>
  );
};

export default BreadcrumbsSkeleton;