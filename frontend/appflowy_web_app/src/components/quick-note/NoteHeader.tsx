import React from 'react';
import { ReactComponent as RightIcon } from '@/assets/arrow_right.svg';
import { ReactComponent as OpenIcon } from '@/assets/full_view.svg';
import { ReactComponent as CollapseIcon } from '@/assets/collapse_all_page.svg';

import { ReactComponent as CloseIcon } from '@/assets/close.svg';

import { IconButton, Tooltip } from '@mui/material';
import { useTranslation } from 'react-i18next';

function NoteHeader({ onBack, onClose, expand, onToggleExpand }: {
  onBack: () => void;
  onClose: () => void;
  expand?: boolean;
  onToggleExpand?: () => void;
}) {
  const { t } = useTranslation();

  return (
    <div className={'flex items-center gap-4'}>
      <IconButton onClick={onBack} size={'small'}>
        <RightIcon className={'transform rotate-180'}/>
      </IconButton>
      <div className={'pl-[24px] text-center font-medium flex-1'}>11</div>
      <Tooltip placement={'top'} title={expand ? t('quickNote.collapseFullView') : t('quickNote.expandFullView')}>
        <IconButton onClick={onToggleExpand} size={'small'}>
          {expand ? <CollapseIcon className={'transform rotate-45'}/> : <OpenIcon/>}
        </IconButton>
      </Tooltip>
      <IconButton onClick={onClose} size={'small'}>
        <CloseIcon/>
      </IconButton>
    </div>
  );
}

export default NoteHeader;