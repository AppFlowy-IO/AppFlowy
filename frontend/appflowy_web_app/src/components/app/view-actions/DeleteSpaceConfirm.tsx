import { NormalModal } from '@/components/_shared/modal';
import { useAppView } from '@/components/app/app.hooks';
import React from 'react';
import { useTranslation } from 'react-i18next';

function DeleteSpaceConfirm ({ open, onClose, viewId }: {
  open: boolean;
  onClose: () => void;
  viewId: string;
}) {
  const view = useAppView(viewId);

  const { t } = useTranslation();

  const handleOk = () => {
    //
  };

  return (
    <NormalModal
      keepMounted={false}
      okText={t('button.delete')}
      cancelText={t('button.cancel')}
      open={open}
      danger={true}
      onClose={onClose}
      title={
        <div className={'flex font-semibold items-center w-full text-left'}>{`${t('button.delete')}: ${view?.name}`}</div>
      }
      onOk={handleOk}
      PaperProps={{
        className: 'w-[420px] max-w-[70vw]',
      }}
    >
      <div className={'text-text-caption font-normal'}>{t('space.deleteConfirmationDescription')}</div>

    </NormalModal>
  );
}

export default DeleteSpaceConfirm;