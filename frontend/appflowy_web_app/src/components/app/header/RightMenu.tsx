import { NormalModal } from '@/components/_shared/modal';
import MoreActions from '@/components/_shared/more-actions/MoreActions';
import { openOrDownload } from '@/utils/open_schema';
import { Button, Divider, Tooltip } from '@mui/material';
import React from 'react';
import { useTranslation } from 'react-i18next';
import ShareButton from 'src/components/app/share/ShareButton';
import { ReactComponent as Logo } from '@/assets/logo.svg';
import { ReactComponent as EditOutlined } from '@/assets/edit.svg';

function RightMenu () {
  const { t } = useTranslation();
  const [comingSoon, setComingSoon] = React.useState(false);

  return (
    <div className={'flex items-center gap-2'}>
      <MoreActions />
      <ShareButton />
      <Button
        size={'small'} startIcon={<EditOutlined />} variant={'outlined'} color={'inherit'}
        onClick={() => setComingSoon(true)}
      >
        {t('button.editing')}
      </Button>
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

      <NormalModal
        onOk={() => setComingSoon(false)} okText={t('button.gotIt')}
        title={
          <div className={'text-left font-semibold'}>{'❤️ Coming Soon'}</div>
        } open={comingSoon} onClose={() => setComingSoon(false)}
      >
        <div className={'text-text-caption'}>
          🌟 This feature is coming soon. Stay tuned!
        </div>
      </NormalModal>
    </div>
  );
}

export default RightMenu;