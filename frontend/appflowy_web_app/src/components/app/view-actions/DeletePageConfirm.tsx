import { NormalModal } from '@/components/_shared/modal';
import { notify } from '@/components/_shared/notify';
import { filterViewsByCondition } from '@/components/_shared/outline/utils';
import { useAppHandlers, useAppView } from '@/components/app/app.hooks';
import React, { useCallback, useEffect, useMemo } from 'react';
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

  const handleOk = useCallback(async () => {
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
  }, [deletePage, onClose, onDeleted, view, viewId]);

  const hasPublished = useMemo(() => {
    const publishedView = filterViewsByCondition(view?.children || [], v => v.is_published);

    return view?.is_published || !!publishedView.length;
  }, [view]);

  useEffect(() => {
    if (!hasPublished && open) {
      void handleOk();
    }
  }, [handleOk, hasPublished, open]);

  if (!hasPublished) return null;

  return (
    <NormalModal
      okLoading={loading}
      keepMounted={false}
      disableRestoreFocus={true}
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