import {
  TemplateCategoryFormValues,
  TemplateCategoryType,
  TemplateIcon,
} from '@/application/template.type';
import { NormalModal } from '@/components/_shared/modal';
import { notify } from '@/components/_shared/notify';
import { useService } from '@/components/app/app.hooks';
import CategoryForm from '@/components/as-template/category/CategoryForm';
import MenuItem from '@mui/material/MenuItem';
import React, { useCallback, useMemo, useState } from 'react';
import { ReactComponent as AddIcon } from '@/assets/add.svg';
import { useTranslation } from 'react-i18next';

function AddCategory ({ searchText, onCreated }: {
  searchText: string;
  onCreated: () => void;
}) {
  const { t } = useTranslation();
  const submitRef = React.useRef<HTMLInputElement>(null);
  const service = useService();
  const defaultValues = useMemo(() => ({
    name: searchText,
    description: '',
    icon: TemplateIcon.project,
    bg_color: '#FFF5F5',
    category_type: TemplateCategoryType.ByUseCase,
    priority: 1,
  }), [searchText]);
  const [openModal, setOpenModal] = useState(false);
  const onSubmit = useCallback(async (data: TemplateCategoryFormValues) => {
    try {
      await service?.addTemplateCategory(data);
      onCreated();
      setOpenModal(false);
    } catch (error) {
      notify.error('Failed to add category');
    }
  }, [onCreated, service]);

  return (
    <>
      <MenuItem onClick={() => {
        setOpenModal(true);
      }} key={'add'} className={'flex gap-2 items-center'}
      >
        <AddIcon className={'w-6 h-6'} />
        {searchText ? searchText : <span className={'text-text-caption'}>{t('template.addNewCategory')}</span>}
      </MenuItem>
      {openModal && <NormalModal
        onOk={() => {
          submitRef.current?.click();
        }}
        title={<div className={'text-left'}>{t('template.addNewCategory')}</div>}
        open={openModal}
        onClose={() => setOpenModal(false)}
        onClick={e => e.stopPropagation()}
        onCancel={() => setOpenModal(false)}
      >
        <CategoryForm defaultValues={defaultValues} ref={submitRef} onSubmit={onSubmit} />
      </NormalModal>}

    </>

  );
}

export default AddCategory;