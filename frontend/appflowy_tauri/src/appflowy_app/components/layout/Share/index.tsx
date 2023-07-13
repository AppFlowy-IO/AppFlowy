import React from 'react';
import { Button } from '@mui/material';
import { useTranslation } from 'react-i18next';
import ButtonPopoverList from '../../_shared/ButtonPopoverList';

function ShareButton() {
  const { t } = useTranslation();

  return (
    <>
      <ButtonPopoverList
        isVisible={true}
        popoverOptions={[]}
        popoverOrigin={{
          anchorOrigin: {
            vertical: 'bottom',
            horizontal: 'right',
          },
          transformOrigin: {
            vertical: 'top',
            horizontal: 'right',
          },
        }}
      >
        <Button variant={'contained'}>{t('shareAction.buttonText')}</Button>
      </ButtonPopoverList>
    </>
  );
}

export default ShareButton;
