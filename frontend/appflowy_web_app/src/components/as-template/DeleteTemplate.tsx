import { NormalModal } from '@/components/_shared/modal';
import { notify } from '@/components/_shared/notify';
import { useService } from '@/components/main/app.hooks';
import React, { useCallback } from 'react';
import { useTranslation } from 'react-i18next';

function DeleteTemplate ({ onDeleted, id, onClose, open }: {
  id: string;
  onClose: () => void;
  open: boolean;
  onDeleted?: () => void;
}) {
  const { t } = useTranslation();
  const service = useService();
  const onSubmit = useCallback(async () => {
    try {
      await service?.deleteTemplate(id);
      onClose();
      onDeleted?.();
      notify.success(t('template.deleteSuccess'));
    } catch (error) {
      notify.error('Failed to delete template');
    }
  }, [t, onClose, service, id, onDeleted]);

  return (
    <NormalModal
      onOk={onSubmit}
      danger
      okText={t('button.delete')}
      title={<div className={'text-left font-semibold'}>{t('template.deleteFromTemplate')}</div>}
      onCancel={onClose}
      open={open}
      onClose={onClose}
      onClick={(e) => e.stopPropagation()}
    >
      {t('template.deleteTemplateDescription')}
    </NormalModal>
  );
}

export default DeleteTemplate;