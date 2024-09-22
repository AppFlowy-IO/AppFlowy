import { NormalModal } from '@/components/_shared/modal';
import { AFConfigContext, useCurrentUser } from '@/components/main/app.hooks';
import { Button, Divider, Typography } from '@mui/material';
import React, { useContext } from 'react';
import { useTranslation, Trans } from 'react-i18next';
import { ReactComponent as AppflowyLogo } from '@/assets/appflowy.svg';
import { useNavigate } from 'react-router-dom';
import { ReactComponent as WarningIcon } from '@/assets/warning.svg';

function RequestAccess () {
  const { t } = useTranslation();
  const currentUser = useCurrentUser();
  const email = currentUser?.email || '';
  const openLoginModal = useContext(AFConfigContext)?.openLoginModal;
  const [clicked, setClicked] = React.useState(false);
  const navigate = useNavigate();
  const [modalOpen, setModalOpen] = React.useState(false);

  return (
    <div className={'m-0 flex h-screen w-screen items-center justify-center bg-bg-body p-0'}>
      <div className={'flex flex-col px-6 items-center gap-3 text-center max-w-[660px] mb-10'}>
        <Typography
          variant="h3" className={'mb-[27px] flex items-center gap-4 text-text-title'} gutterBottom
        >
          <>
            <AppflowyLogo className={'w-48'} />
          </>
        </Typography>
        <div className={'mb-[16px] max-md:text-[24px]  text-[52px] font-semibold leading-[128%] text-text-title'}>
          {t('requestAccess.title')}
        </div>
        <div className={'text-[20px] max-md:text-[16px]  leading-[152%] text-text-caption'}>
          <div>{t('requestAccess.subtitle')}</div>
        </div>
        <div className={'flex items-center mt-4 w-full gap-4 justify-between'}>
          <Button
            onClick={() => {
              setModalOpen(true);
              setClicked(true);
            }}
            disabled={clicked}
            className={'flex-1 py-2 px-4 rounded-[8px] text-[20px] font-medium max-md:text-base max-sm:text-[14px] max-md:py-2'}
            variant={'contained'} color={'primary'}
          >
            {t('requestAccess.requestAccess')}
          </Button>
          <Button
            onClick={() => {
              navigate('/');
            }}
            className={'flex-1 py-2 px-4 rounded-[8px] max-sm:text-[14px] max-md:text-base text-[20px] font-medium max-md:py-2'}
            variant={'outlined'} color={'inherit'}
          >
            {t('requestAccess.backToHome')}
          </Button>
        </div>
        <Divider className={'w-full mb-3 mt-4'} />
        <div className={'max-w-[400px] flex flex-col text-text-caption'}>
           <span>
             <Trans
               i18nKey="requestAccess.tip"
               components={{ link: <span className={'underline text-fill-default'}>{email}</span> }}
             />
           </span>
          <span>
            <Trans
              i18nKey="requestAccess.mightBe"
              components={{
                login: <span
                  onClick={() => openLoginModal?.()} className={'underline text-fill-default cursor-pointer'}
                >{t('signIn.logIn')}</span>,
              }}
            />
           </span>
        </div>
      </div>
      <NormalModal
        onCancel={() => {
          setModalOpen(false);
        }} onOk={() => {
        setModalOpen(false);
      }} title={
        <div className={'text-left font-semibold gap-1.5 flex items-center'}>
          <WarningIcon className={'w-4 h-4'} />
          Coming soon</div>
      } open={modalOpen} onClose={() => setModalOpen(false)}
      >
        This feature is coming soon. Please contact the owner of this workspace to request access.
      </NormalModal>
    </div>
  );
}

export default RequestAccess;