import React from 'react';
import { Typography, Button } from '@mui/material';
import { useTranslation } from 'react-i18next';
import { Link, useNavigate } from 'react-router-dom';
import { ReactComponent as AppflowyLogo } from '@/assets/appflowy.svg';

const NotFound = () => {
  const { t } = useTranslation();
  const navigate = useNavigate();

  return (
    <div className={'m-0 flex h-screen w-screen items-center justify-center bg-bg-body p-0'}>
      <div className={'flex flex-col items-center gap-1 text-center'}>
        <Typography variant="h3" className={'mb-[27px] flex items-center gap-4 text-text-title'} gutterBottom>
          <AppflowyLogo className={'w-32'} />
        </Typography>
        <div className={'mb-[16px] text-[52px] font-semibold leading-[128%] text-text-title max-sm:text-[24px]'}>
          {t('publish.noAccessToVisit')}
        </div>
        <div className={'text-[20px] leading-[152%]'}>
          <div>{t('publish.createWithAppFlowy')}</div>
          <div className={'flex items-center gap-1'}>
            <div className={'font-semibold text-fill-default'}>{t('publish.fastWithAI')}</div>
            <div>{t('publish.tryItNow')}</div>
          </div>
        </div>
        <div className={'flex items-center px-2 max-sm:flex-col mt-4 w-full gap-4 justify-between'}>
          <Button
            component={Link}
            to="https://appflowy.io/download"
            variant="contained"
            color="primary"
            className={'flex-1 py-3 px-4 max-sm:w-full rounded-[8px] max-md:text-base text-[20px] font-medium'}
          >
            {t('publish.downloadApp')}
          </Button>
          <Button
            onClick={() => {
              navigate('/');
            }}
            className={'flex-1 py-3 px-4 max-sm:w-full rounded-[8px] max-md:text-base text-[20px] font-medium'}
            variant={'outlined'} color={'inherit'}
          >
            {t('requestAccess.backToHome')}
          </Button>
        </div>

      </div>
    </div>
  );
};

export default NotFound;
