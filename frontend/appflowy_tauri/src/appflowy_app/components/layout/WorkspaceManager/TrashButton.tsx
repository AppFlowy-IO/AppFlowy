import React from 'react';
import { TrashSvg } from '$app/components/_shared/svg/TrashSvg';
import MenuItem from '@mui/material/MenuItem';
import { useTranslation } from 'react-i18next';
import { useLocation, useNavigate } from 'react-router-dom';

function TrashButton() {
  const { t } = useTranslation();
  const navigate = useNavigate();
  const currentPathType = useLocation().pathname.split('/')[1];
  const navigateToTrash = () => {
    navigate('/trash');
  };

  return (
    <MenuItem
      data-page-id={'trash'}
      selected={currentPathType === 'trash'}
      onClick={navigateToTrash}
      style={{
        borderRadius: '8px',
      }}
      className={'flex w-[100%] items-center'}
    >
      <div className='h-6 w-6'>
        <TrashSvg />
      </div>
      <span className={'ml-2'}>{t('trash.text')}</span>
    </MenuItem>
  );
}

export default TrashButton;
