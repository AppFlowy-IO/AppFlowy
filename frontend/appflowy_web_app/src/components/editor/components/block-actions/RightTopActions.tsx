import { Divider, IconButton, Tooltip } from '@mui/material';
import React from 'react';
import { useTranslation } from 'react-i18next';
import { ReactComponent as CopyIcon } from '@/assets/copy.svg';
import { ReactComponent as DownloadIcon } from '@/assets/download.svg';

export interface RightTopActionsProps {
  onCopy: () => void;
  onDownload?: () => void;
}

function RightTopActions ({ onCopy, onDownload }: RightTopActionsProps) {
  const { t } = useTranslation();

  return (
    <div className={'flex w-fit flex-grow transform p-1 items-center justify-end gap-1 rounded bg-bg-body shadow-lg'}>
      <Tooltip title={t('editor.copy')}>
        <IconButton onClick={e => {
          e.stopPropagation();
          onCopy();
        }}
        >
          <CopyIcon className={'h-6 w-6'} />
        </IconButton>
      </Tooltip>

      {onDownload && <>
        <Divider orientation={'vertical'} flexItem />
        <Tooltip title={t('button.download')}>
          <IconButton className={'p-1'} onClick={e => {
            e.stopPropagation();
            onDownload?.();
          }}
          >
            <DownloadIcon className={'h-5 w-5'} />
          </IconButton>
        </Tooltip>
      </>}
    </div>
  );
}

export default RightTopActions;
