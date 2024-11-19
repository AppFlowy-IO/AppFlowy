import { NormalModal } from '@/components/_shared/modal';
import { notify } from '@/components/_shared/notify';
import { useAppHandlers, useAppView } from '@/components/app/app.hooks';
import React from 'react';
import { useTranslation } from 'react-i18next';

function DeleteSpaceConfirm ({ open, onClose, viewId }: {
  open: boolean;
  onClose: () => void;
  viewId: string;
}) {
  const view = useAppView(viewId);

  const [loading, setLoading] = React.useState(false);
  const {
    deletePage,
  } = useAppHandlers();
  const { t } = useTranslation();

  const handleOk = async () => {
    if (!view) return;
    setLoading(true);
    try {
      await deletePage?.(viewId);
      onClose();
      // eslint-disable-next-line
    } catch (e: any) {
      notify.error(e.message);
    } finally {
      setLoading(false);
    }
  };

  return (
    <NormalModal
      keepMounted={false}
      okText={t('button.delete')}
      cancelText={t('button.cancel')}
      open={open}
      danger={true}
      onClose={onClose}
      okLoading={loading}
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