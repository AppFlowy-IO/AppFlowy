import {
  TemplateCategory,
  TemplateCategoryFormValues,
} from '@/application/template.type';
import { NormalModal } from '@/components/_shared/modal';
import { notify } from '@/components/_shared/notify';
import { useService } from '@/components/app/app.hooks';
import CategoryForm from '@/components/as-template/category/CategoryForm';
import React, { useCallback } from 'react';
import { useTranslation } from 'react-i18next';

function EditCategory ({
  category,
  onUpdated,
  openModal,
  onClose,
}: {
  category: TemplateCategory;
  onUpdated: () => void;
  openModal: boolean;
  onClose: () => void;
}) {
  const { t } = useTranslation();
  const submitRef = React.useRef<HTMLInputElement>(null);
  const service = useService();
  const onSubmit = useCallback(async (data: TemplateCategoryFormValues) => {
    console.log('data', data);
    try {
      await service?.updateTemplateCategory(category.id, data);
      onUpdated();
      onClose();
    } catch (error) {
      notify.error('Failed to update category');
    }
  }, [onUpdated, onClose, service, category.id]);

  return (
    <NormalModal
      onClick={e => e.stopPropagation()}
      onOk={() => {
        submitRef.current?.click();
      }}
      title={<div className={'text-left'}>{t('template.editCategory')}</div>}
      onCancel={onClose}
      open={openModal}
      onClose={onClose}
    >
      <CategoryForm defaultValues={category} ref={submitRef} onSubmit={onSubmit} />
    </NormalModal>
  );
}

export default EditCategory;