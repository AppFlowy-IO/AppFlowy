import { TemplateSummary } from '@/application/template.type';
import { NormalModal } from '@/components/_shared/modal';
import { useLoadCategories } from '@/components/as-template/hooks';
import CategoryTemplates from '@/components/as-template/related-template/CategoryTemplates';
import { Button, CircularProgress } from '@mui/material';
import React from 'react';
import { useTranslation } from 'react-i18next';
import { ReactComponent as AddIcon } from '@/assets/add.svg';

function AddRelatedTemplates ({
  selectedTemplateIds,
  onChange,
  updateTemplate,
}: {
  selectedTemplateIds: string[]
  onChange: (value: string[]) => void;
  updateTemplate: (template: TemplateSummary) => void;
}) {
  const {
    categories,
    loadCategories,
    loading,
  } = useLoadCategories();

  const [openModal, setOpenModal] = React.useState(false);
  const { t } = useTranslation();

  return (
    <>
      <Button onClick={() => {
        void loadCategories();
        setOpenModal(true);
      }} className={'w-full'} color={'inherit'} startIcon={<AddIcon />} variant={'outlined'}
      >{t('template.addRelatedTemplate')}</Button>
      {openModal &&
        <NormalModal
          title={<div className={'text-left'}>{t('template.addRelatedTemplate')}</div>}
          open={openModal}
          onClose={() => setOpenModal(false)}
          onCancel={() => setOpenModal(false)}
          onOk={() => {
            setOpenModal(false);
          }}
          fullWidth={true}
        >
          <div className={'flex flex-col justify-center gap-4'}>
            {loading ?
              <CircularProgress /> :
              categories.map(item =>
                (<CategoryTemplates
                  key={item.id}
                  category={item}
                  updateTemplate={updateTemplate}
                  selectedTemplateIds={selectedTemplateIds}
                  onChange={onChange}
                />),
              )
            }
          </div>
        </NormalModal>}
    </>
  );
}

export default AddRelatedTemplates;