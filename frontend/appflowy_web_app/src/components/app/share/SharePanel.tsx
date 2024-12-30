import React from 'react';
import { ReactComponent as ShareIcon } from '@/assets/share_tab_icon.svg';
import { ReactComponent as LinkIcon } from '@/assets/share.svg';

import { useTranslation } from 'react-i18next';
import { Button, OutlinedInput } from '@mui/material';
import { copyTextToClipboard } from '@/utils/copy';
import { notify } from '@/components/_shared/notify';

function SharePanel() {
  const { t } = useTranslation();

  const handleCopy = () => {
    void copyTextToClipboard(window.location.href);
    notify.success(t('shareAction.copyLinkSuccess'));
  };

  return (
    <div className={'flex flex-col w-full pb-2 px-1'}>
      <div className={'text-sm flex w-full items-center gap-2'}>
        <ShareIcon className={'w-4 h-4'}/>
        <span>{t('shareAction.shareTabTitle')}</span>
      </div>
      <div className={'text-sm w-full text-text-caption flex items-center gap-2'}>
        {t('shareAction.shareTabDescription')}
      </div>
      <div className={'text-sm mt-4 w-full flex items-center gap-2'}>
        <OutlinedInput
          onClick={e => {
            if (e.detail > 2) {
              e.preventDefault();
              e.stopPropagation();
              handleCopy();
            }
          }}
          size={'small'} className={'flex-1'} readOnly={true} value={window.location.href}/>
        <Button
          variant={'contained'}
          color={'primary'}
          className={'flex-nowrap h-[40px] rounded-[12px]'}
          onClick={handleCopy}
          startIcon={<LinkIcon className={'w-4 h-4'}/>}
        >
          <span className={'whitespace-nowrap'}> {t('shareAction.copyLink')}</span>
        </Button>
      </div>
    </div>
  );
}

export default SharePanel;