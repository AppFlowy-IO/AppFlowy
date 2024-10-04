import NormalModal from '@/components/_shared/modal/NormalModal';
import { AFConfigContext, useCurrentUser } from '@/components/main/app.hooks';
import React, { useContext } from 'react';
import { useTranslation } from 'react-i18next';
import { useNavigate } from 'react-router-dom';
import { ReactComponent as ErrorIcon } from '@/assets/error.svg';

function ChangeAccount ({
  setModalOpened,
  modalOpened,
}: {
  setModalOpened: (opened: boolean) => void;
  modalOpened: boolean;

}) {
  const currentUser = useCurrentUser();
  const navigate = useNavigate();
  const openLoginModal = useContext(AFConfigContext)?.openLoginModal;
  const { t } = useTranslation();

  return (
    <NormalModal
      onCancel={() => {
        setModalOpened(false);
        navigate('/');
      }}
      closable={false}
      cancelText={t('invitation.errorModal.close')}
      onOk={openLoginModal}
      okText={t('invitation.errorModal.changeAccount')}
      title={<div className={'text-left font-bold flex gap-2 items-center'}>
        <ErrorIcon className={'w-5 h-5 text-function-error'} />
        {t('invitation.errorModal.title')}
      </div>}
      open={modalOpened}
    >
      <div className={'text-text-title flex flex-col text-sm gap-1 whitespace-pre-wrap break-words'}>
        {t('invitation.errorModal.description', {
          email: currentUser?.email,
        })}
      </div>
    </NormalModal>
  );
}

export default ChangeAccount;