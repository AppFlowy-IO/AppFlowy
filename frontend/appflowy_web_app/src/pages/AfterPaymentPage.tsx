import { openOrDownload } from '@/components/publish/header/utils';
import { Button, Typography } from '@mui/material';
import React from 'react';
import { ReactComponent as Logo } from '@/assets/logo.svg';
import { ReactComponent as AppflowyLogo } from '@/assets/appflowy.svg';

function AfterPaymentPage() {
  return (
    <div className={'m-0 flex h-screen w-screen items-center justify-center bg-bg-body p-0'}>
      <div className={'flex max-w-[560px] flex-col items-center gap-1 text-center'}>
        <Typography variant='h3' className={'mb-[27px] flex items-center gap-4 text-text-title'} gutterBottom>
          <>
            <Logo className={'w-9'} />
            <AppflowyLogo className={'w-32'} />
          </>
        </Typography>
        <div className={'mb-[16px] text-[52px] font-semibold leading-[128%] text-text-title'}>
          Explore features in your new plan
        </div>
        <div className={'flex flex-col items-center  justify-center  text-[20px] leading-[152%]'}>
          <div>
            Congratulations! You just unlocked more workspace members and <span className={''}>unlimited</span> AI
            responses. 🎉
          </div>
        </div>
        <Button
          onClick={openOrDownload}
          variant='contained'
          color='primary'
          className={
            'mt-[32px] mb-[48px] h-[68px] rounded-[20px] px-[44px] py-[18px] text-[20px] font-medium leading-[120%] text-content-on-fill'
          }
        >
          Back to AppFlowy
        </Button>
      </div>
    </div>
  );
}

export default AfterPaymentPage;
