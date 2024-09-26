import MoreActions from '@/components/_shared/more-actions/MoreActions';
import { openOrDownload } from '@/utils/open_schema';
import { Divider, Tooltip } from '@mui/material';
import React from 'react';
import { useTranslation } from 'react-i18next';
import ShareButton from 'src/components/app/share/ShareButton';
import { ReactComponent as Logo } from '@/assets/logo.svg';

function RightMenu () {
  const { t } = useTranslation();
  
  return (
    <div className={'flex items-center gap-2'}>
      <MoreActions />
      <ShareButton />
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
    </div>
  );
}

export default RightMenu;