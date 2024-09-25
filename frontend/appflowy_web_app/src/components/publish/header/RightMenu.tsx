import MoreActions from '@/components/_shared/more-actions/MoreActions';
import { openOrDownload } from '@/utils/open_schema';
import { Divider, Tooltip } from '@mui/material';
import React from 'react';
import { ReactComponent as Logo } from '@/assets/logo.svg';
import { Duplicate } from '@/components/publish/header/duplicate';
import { useTranslation } from 'react-i18next';

function RightMenu () {
  const { t } = useTranslation();

  return (
    <>
      <MoreActions />
      <Duplicate />

      <Divider
        orientation={'vertical'}
        className={'mx-2'}
        flexItem
      />
      <Tooltip title={t('publish.downloadApp')}>
        <button onClick={() => openOrDownload()}>
          <Logo className={'h-6 w-6'} />
        </button>
      </Tooltip>
    </>
  );
}

export default RightMenu;