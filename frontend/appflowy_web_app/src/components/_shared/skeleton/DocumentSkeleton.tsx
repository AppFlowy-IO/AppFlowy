import { Box, Typography } from '@mui/material';
import Skeleton from '@mui/material/Skeleton';
import React from 'react';

function DocumentSkeleton () {
  return (
    <Box className={'w-[964px] min-w-0 max-w-full px-6'} sx={{ marginTop: 2 }}>
      <Typography variant="h1">
        <Skeleton variant="text" width="100%" />
      </Typography>
      <Skeleton variant="text" width="50%" />
      <Typography variant="h2">
        <Skeleton variant="text" width="60%" />
      </Typography>
      <Typography variant="h3">
        <Skeleton variant="text" width="80%" />
      </Typography>
      <Skeleton variant="text" width="100%" />
      <Skeleton variant="text" width="100%" />
    </Box>
  );
}

export default DocumentSkeleton;
