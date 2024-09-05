import { Box, Skeleton } from '@mui/material';
import './skeleton.scss';

export const DirectoryStructure = () => {
  return (
    <Box className={'w-full'}>
      <div className="directory-item">
        <Skeleton variant="circular" width={20} height={20} />
        <Skeleton variant="text" className={'flex-1'} />
      </div>
      <div className="nested">
        <div className="directory-item">
          <Skeleton variant="circular" width={20} height={20} />
          <Skeleton variant="text" className={'flex-1'} />
        </div>
        <div className="nested">
          <div className="directory-item">
            <Skeleton variant="circular" width={20} height={20} />
            <Skeleton variant="text" className={'flex-1'} />
          </div>
          <div className="directory-item">
            <Skeleton variant="circular" width={20} height={20} />
            <Skeleton variant="text" className={'flex-1'} />
          </div>
        </div>
        <div className="directory-item">
          <Skeleton variant="circular" width={20} height={20} />
          <Skeleton variant="text" className={'flex-1'} />
        </div>
      </div>
      <div className="directory-item">
        <Skeleton variant="circular" width={20} height={20} />
        <Skeleton variant="text" className={'flex-1'} />
      </div>
      <div className="nested">
        <div className="directory-item">
          <Skeleton variant="circular" width={20} height={20} />
          <Skeleton variant="text" className={'flex-1'} />
        </div>
        <div className="directory-item">
          <Skeleton variant="circular" width={20} height={20} />
          <Skeleton variant="text" className={'flex-1'} />
        </div>
      </div>
    </Box>
  );
};