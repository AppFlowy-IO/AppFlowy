import { NormalModal } from '@/components/_shared/modal';
import { notify } from '@/components/_shared/notify';
import { useAppHandlers, useAppView } from '@/components/app/app.hooks';
import React from 'react';
import { useTranslation } from 'react-i18next';

function DeletePageConfirm ({ open, onClose, viewId, onDeleted }: {
  open: boolean;
  onClose: () => void;
  viewId: string;
  onDeleted?: () => void;
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
      onDeleted?.();
      // eslint-disable-next-line
    } catch (e: any) {
      notify.error(e.message);
    } finally {
      setLoading(false);
    }
  };

  return (
    <NormalModal
      okLoading={loading}
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
      <div className={'text-text-caption font-normal'}>{t('publish.containsPublishedPage')}</div>

    </NormalModal>
  );
}

export default DeletePageConfirm;