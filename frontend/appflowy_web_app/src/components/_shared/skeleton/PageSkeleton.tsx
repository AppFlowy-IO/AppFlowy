import React from 'react';
import { Skeleton, Box, Typography } from '@mui/material';

function PageSkeleton ({
  hasName = false,
  hasIcon = false,
  hasCover = false,
}: {
  hasName?: boolean;
  hasIcon?: boolean;
  hasCover?: boolean;
}) {
  return (
    <Box className={'flex flex-col items-center'} sx={{ width: '100%', maxWidth: '100%', margin: 'auto' }}>
      {hasCover && (
        <Skeleton
          variant="rectangular"
          width="100%"
          style={{
            height: '40vh',
          }}
          className={'relative flex max-h-[288px] min-h-[130px] w-full max-sm:h-[180px]'}
        />
      )}

      <Box sx={{ height: hasCover ? 60 : 100 }} />

      <Box className={'w-[964px] min-w-0 max-w-full px-6'}
           sx={{ display: 'flex', alignItems: 'center', height: 80, marginBottom: 2 }}
      >
        {hasIcon && (
          <Skeleton
            variant="circular"
            width={60}
            height={60}
            sx={{ flexShrink: 0 }}
          />
        )}
        {hasName && (
          <Skeleton
            variant="rounded"
            width="100%"
            height={40}
            sx={{ marginLeft: hasIcon ? 2 : 0 }}
          />
        )}
      </Box>

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
    </Box>
  );
}

export default PageSkeleton;