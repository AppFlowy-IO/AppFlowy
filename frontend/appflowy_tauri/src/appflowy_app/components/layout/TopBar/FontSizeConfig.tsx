import React from 'react';
import { useTranslation } from 'react-i18next';
import { ButtonGroup, Divider } from '@mui/material';
import Button from '@mui/material/Button';

function FontSizeConfig() {
  const { t } = useTranslation();

  return (
    <>
      <div className={'flex flex-col justify-center p-4'}>
        <div className={'py-2 text-sm text-text-caption'}>{t('moreAction.fontSize')}</div>
        <div className={'flex items-center justify-around pt-2'}>
          <ButtonGroup variant='text' color={'inherit'}>
            <Button>{t('moreAction.small')}</Button>
            <Button color={'primary'}>{t('moreAction.medium')}</Button>
            <Button>{t('moreAction.large')}</Button>
          </ButtonGroup>
        </div>
      </div>
      <Divider />
    </>
  );
}

export default FontSizeConfig;
