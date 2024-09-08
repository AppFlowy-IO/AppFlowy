import { NormalModal } from '@/components/_shared/modal';
import { notify } from '@/components/_shared/notify';
import { useService } from '@/components/app/app.hooks';
import React, { useCallback } from 'react';
import { useTranslation } from 'react-i18next';

function DeleteCategory ({ id, onClose, onDeleted, open }: {
  id: string;
  onClose: () => void;
  onDeleted: () => void;
  open: boolean;
}) {
  const { t } = useTranslation();
  const service = useService();
  const onSubmit = useCallback(async () => {
    try {
      await service?.deleteTemplateCategory(id);
      onDeleted();
      onClose();
    } catch (error) {
      notify.error('Failed to delete category');
    }
  }, [onDeleted, onClose, service, id]);

  return (
    <NormalModal
      onOk={onSubmit}
      danger
      okText={t('button.delete')}
      title={<div className={'text-left'}>{t('template.category.deleteCategory')}</div>}
      onCancel={onClose}
      open={open}
      onClose={onClose}
      onClick={(e) => e.stopPropagation()}
    >
      {t('template.category.deleteCategoryDescription')}
    </NormalModal>
  );
}

export default DeleteCategory;