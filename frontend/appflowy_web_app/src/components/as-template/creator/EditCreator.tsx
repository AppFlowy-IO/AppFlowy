import { TemplateCreator, TemplateCreatorFormValues } from '@/application/template.type';
import { NormalModal } from '@/components/_shared/modal';
import { notify } from '@/components/_shared/notify';
import { useService } from '@/components/app/app.hooks';
import CreatorForm from '@/components/as-template/creator/CreatorForm';
import React, { useCallback } from 'react';
import { useTranslation } from 'react-i18next';

function EditCreator ({
  creator,
  onUpdated,
  openModal,
  onClose,
}: {
  creator: TemplateCreator;
  onUpdated: () => void;
  openModal: boolean;
  onClose: () => void;
}) {
  const { t } = useTranslation();
  const submitRef = React.useRef<HTMLInputElement>(null);
  const service = useService();

  const onSubmit = useCallback(async (data: TemplateCreatorFormValues) => {
    try {
      await service?.updateTemplateCreator(creator.id, data);
      onUpdated();
      onClose();
    } catch (error) {
      notify.error('Failed to update creator');
    }
  }, [onUpdated, service, onClose, creator.id]);

  return (
    <NormalModal
      onCancel={onClose}
      onOk={() => {
        submitRef.current?.click();
      }}
      onClick={e => e.stopPropagation()}
      title={<div className={'text-left'}>{t('template.editCreator')}</div>} open={openModal}
      onClose={onClose}
    >
      <div className={'overflow-hidden w-[500px]'}>
        <CreatorForm defaultValues={creator} ref={submitRef} onSubmit={onSubmit} />
      </div>
    </NormalModal>
  );
}

export default EditCreator;