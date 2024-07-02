import { IconButton, Tooltip } from '@mui/material';
import React from 'react';
import { useTranslation } from 'react-i18next';
import { ReactComponent as CopyIcon } from '@/assets/copy.svg';

function RightTopActions({ onCopy }: { onCopy: () => void }) {
  const { t } = useTranslation();

  return (
    <div className={'flex w-fit flex-grow transform items-center justify-end gap-2 rounded bg-bg-body shadow-lg'}>
      <Tooltip title={t('editor.copy')}>
        <IconButton onClick={onCopy}>
          <CopyIcon className={'h-6 w-6'} />
        </IconButton>
      </Tooltip>
    </div>
  );
}

export default RightTopActions;
