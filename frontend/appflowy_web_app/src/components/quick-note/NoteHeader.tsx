import React, { useMemo } from 'react';
import { ReactComponent as RightIcon } from '@/assets/arrow_right.svg';
import { ReactComponent as OpenIcon } from '@/assets/full_view.svg';
import { ReactComponent as CollapseIcon } from '@/assets/collapse_all_page.svg';

import { ReactComponent as CloseIcon } from '@/assets/close.svg';

import { IconButton } from '@mui/material';
import { useTranslation } from 'react-i18next';
import { QuickNote } from '@/application/types';
import { getTitle } from '@/components/quick-note/utils';

function NoteHeader({ note, onBack, onClose, expand, onToggleExpand }: {
  onBack: () => void;
  onClose: () => void;
  expand?: boolean;
  onToggleExpand?: () => void;
  note: QuickNote;
}) {
  const { t } = useTranslation();

  const title = useMemo(() => {
    return getTitle(note) || t('menuAppHeader.defaultNewPageName');
  }, [note, t]);

  return (
    <div className={'flex items-center gap-4 w-full overflow-hidden'}>
      <IconButton onClick={onBack} size={'small'}>
        <RightIcon className={'transform rotate-180'}/>
      </IconButton>
      <div className={'pl-[24px] truncate text-center font-medium flex-1'}>
        {title}
      </div>
      <IconButton onClick={onToggleExpand} size={'small'}>
        {expand ? <CollapseIcon className={'transform rotate-45'}/> : <OpenIcon/>}
      </IconButton>
      <IconButton onClick={onClose} size={'small'}>
        <CloseIcon/>
      </IconButton>
    </div>
  );
}

export default NoteHeader;