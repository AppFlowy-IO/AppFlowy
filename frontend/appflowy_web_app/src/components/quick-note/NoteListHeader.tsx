import React from 'react';
import { ReactComponent as SearchIcon } from '@/assets/search.svg';
import { ReactComponent as CloseIcon } from '@/assets/close.svg';
import { ReactComponent as OpenIcon } from '@/assets/full_view.svg';
import { ReactComponent as CollapseIcon } from '@/assets/collapse_all_page.svg';

import { IconButton, InputBase, Tooltip } from '@mui/material';
import { useTranslation } from 'react-i18next';
import { createHotkey, HOT_KEY_NAME } from '@/utils/hotkeys';

function NoteListHeader({
  onClose,
  expand, onToggleExpand,
}: {
  onEnterNote: () => void;
  onClose: () => void;
  expand?: boolean;
  onToggleExpand?: () => void;
}) {
  const { t } = useTranslation();
  const [activeSearch, setActiveSearch] = React.useState(false);
  const inputRef = React.useRef<HTMLInputElement>(null);

  return (
    <div
      className={'flex relative items-center w-full h-full gap-4'}
    >
      <IconButton
        className={`z-[2] ${activeSearch ? 'order-1 cursor-default hover:bg-transparent' : 'order-2'}`}
        onClick={(e) => {
          e.stopPropagation();
          if (!activeSearch) {
            inputRef.current?.focus();
            setActiveSearch(true);
          }
        }} size={'small'}>
        <SearchIcon/>
      </IconButton>
      <div className={'flex-1 order-1'}>
        {activeSearch ?
          <InputBase
            className={'flex-1'}
            inputProps={{
              className: 'pb-0',
            }}
            autoFocus={true}
            onKeyDown={e => {
              if (activeSearch && createHotkey(HOT_KEY_NAME.ESCAPE)(e.nativeEvent)) {
                e.stopPropagation();
                setActiveSearch(false);
              }
            }}
            inputRef={inputRef}
            size={'small'}
            placeholder={t('quickNote.search')}
          /> :
          <div className={'flex-1 ml-8 text-center font-medium text-base'}>{t('quickNote.quickNotes')}</div>
        }
      </div>

      <Tooltip placement={'top'} title={expand ? t('quickNote.collapseFullView') : t('quickNote.expandFullView')}>
        <IconButton onClick={onToggleExpand} size={'small'}>
          {expand ? <CollapseIcon className={'transform rotate-45'}/> : <OpenIcon/>}
        </IconButton>
      </Tooltip>

      <IconButton className={'order-2'} onClick={() => {
        if (activeSearch) {
          setActiveSearch(false);
        } else {
          onClose();
        }
      }} size={'small'}>
        <CloseIcon/>
      </IconButton>
    </div>
  );
}

export default NoteListHeader;