import {
  TemplateCreatorFormValues,
} from '@/application/template.type';
import { NormalModal } from '@/components/_shared/modal';
import { notify } from '@/components/_shared/notify';
import { useService } from '@/components/main/app.hooks';
import CreatorForm from '@/components/as-template/creator/CreatorForm';
import MenuItem from '@mui/material/MenuItem';
import React, { useCallback, useMemo, useState } from 'react';
import { ReactComponent as AddIcon } from '@/assets/add.svg';
import { useTranslation } from 'react-i18next';

function AddCreator ({ searchText, onCreated }: {
  searchText: string;
  onCreated: () => void;
}) {
  const { t } = useTranslation();
  const submitRef = React.useRef<HTMLInputElement>(null);
  const service = useService();

  const defaultValues = useMemo(() => ({
    name: searchText,
    avatar_url: '',
    account_links: [],
  }), [searchText]);

  const [openModal, setOpenModal] = useState(false);
  const handleClose = useCallback(() => {
    setOpenModal(false);
  }, []);

  const onSubmit = useCallback(async (data: TemplateCreatorFormValues) => {
    console.log('data', data);
    try {
      await service?.createTemplateCreator(data);
      onCreated();
      handleClose();
    } catch (error) {
      notify.error('Failed to create creator');
    }
  }, [onCreated, service, handleClose]);

  return (
    <>
      <MenuItem key={'add'} className={'flex gap-2 items-center'} onClick={() => setOpenModal(true)}>
        <AddIcon className={'w-6 h-6'} />
        {searchText ? searchText : <span className={'text-text-caption'}>{t('template.addNewCreator')}</span>}
      </MenuItem>
      {openModal && <NormalModal
        onClick={e => e.stopPropagation()}
        onCancel={handleClose}
        onOk={() => {
          submitRef.current?.click();
        }} title={<div className={'text-left'}>{t('template.addNewCreator')}</div>} open={openModal}
        onClose={handleClose}
      >
        <div className={'overflow-hidden w-[500px]'}>
          <CreatorForm ref={submitRef} onSubmit={onSubmit} defaultValues={defaultValues} />
        </div>
      </NormalModal>}

    </>
  );
}

export default AddCreator;