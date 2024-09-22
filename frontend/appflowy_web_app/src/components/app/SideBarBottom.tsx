import { Button, Divider } from '@mui/material';
import React from 'react';
import { useTranslation } from 'react-i18next';
import Trash from 'src/components/app/trash/Trash';
import { ReactComponent as TemplateIcon } from '@/assets/template.svg';

function SideBarBottom () {
  const { t } = useTranslation();

  return (
    <div
      className={'flex border-t border-line-divider py-4 px-4 gap-1 justify-between items-center sticky bottom-0 bg-bg-body'}
    >
      <Button
        startIcon={<TemplateIcon className={'h-5 w-5'} />}
        size={'small'}
        onClick={() => {
          window.open('https://appflowy.io/templates', '_blank');
        }}
        variant={'text'}
        className={'flex-1'}
        color={'inherit'}
      >
        {t('template.label')}
      </Button>
      <Divider orientation={'vertical'} flexItem />
      <Trash />
    </div>
  );
}

export default SideBarBottom;