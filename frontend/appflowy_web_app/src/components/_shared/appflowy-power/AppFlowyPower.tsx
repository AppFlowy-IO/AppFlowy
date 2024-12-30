import { Divider } from '@mui/material';
import React from 'react';
import { ReactComponent as AppFlowyLogo } from '@/assets/appflowy.svg';

function AppFlowyPower ({
  divider,
  width,
}: {
  divider?: boolean;
  width?: number;
}) {
  return (
    <div
      style={{
        width,
      }}
      className={'flex rounded-[16px] transform-gpu bg-bg-body sticky bottom-[-0.5px] w-full flex-col items-center justify-center'}
    >
      {divider && <Divider className={'w-full my-0'} />}

      <div
        onClick={() => {
          window.open('https://appflowy.io', '_blank');
        }}
        style={{
          width,
        }}
        className={
          'flex  w-full cursor-pointer gap-2 items-center justify-center py-4 text-sm text-text-title opacity-50'
        }
      >
        Powered by
        <AppFlowyLogo className={'w-[88px]'} />
      </div>
    </div>
  );
}

export default AppFlowyPower;