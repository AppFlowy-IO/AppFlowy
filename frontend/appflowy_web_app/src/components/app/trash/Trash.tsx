import { Button } from '@mui/material';
import React from 'react';
import { useTranslation } from 'react-i18next';
import { useNavigate } from 'react-router-dom';
import { ReactComponent as TrashIcon } from '@/assets/trash.svg';

export function Trash () {
  const { t } = useTranslation();
  const navigate = useNavigate();

  return (
    <Button
      size={'small'} onClick={() => {
      navigate('/app/trash');
    }}
      variant={'text'}
      color={'inherit'}
      className={'flex-1'}
      startIcon={<TrashIcon className={'h-5 w-5'} />}
    >{
      t('trash.text')
    }</Button>
  );
}

export default Trash;