import React from 'react';
import { useTranslation } from 'react-i18next';
import { IconButton } from '@mui/material';
import { Details2Svg } from '$app/components/_shared/svg/Details2Svg';
import ButtonPopoverList from '../../_shared/ButtonPopoverList';

function MoreButton() {
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
        <IconButton className={'h-8 w-8 text-icon-primary'}>
          <Details2Svg />
        </IconButton>
      </ButtonPopoverList>
    </>
  );
}

export default MoreButton;
