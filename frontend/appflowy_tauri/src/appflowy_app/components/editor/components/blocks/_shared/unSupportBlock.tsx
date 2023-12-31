import React, { forwardRef } from 'react';
import { Alert } from '@mui/material';

export const UnSupportBlock = forwardRef<HTMLDivElement, void>((_, ref) => {
  return (
    <div ref={ref}>
      <Alert className={'h-[48px] w-full'} title={'Unsupported block'} severity={'error'} />
    </div>
  );
});

export default UnSupportBlock;
