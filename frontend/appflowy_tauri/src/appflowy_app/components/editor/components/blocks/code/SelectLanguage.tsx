import React, { useCallback, useEffect, useMemo, useRef, useState } from 'react';
import { TextField, Popover } from '@mui/material';
import { useTranslation } from 'react-i18next';
import { supportLanguage } from './constants';
import KeyboardNavigation, {
  KeyboardNavigationOption,
} from '$app/components/_shared/keyboard_navigation/KeyboardNavigation';
import usePopoverAutoPosition from '$app/components/_shared/popover/Popover.hooks';
import { PopoverOrigin } from '@mui/material/Popover/Popover';

const initialOrigin: {
  transformOrigin: PopoverOrigin;
  anchorOrigin: PopoverOrigin;
} = {
  transformOrigin: {
    vertical: 'top',
    horizontal: 'left',
  },
  anchorOrigin: {
    vertical: 'bottom',
    horizontal: 'left',
  },
};

function SelectLanguage({
  language = 'json',
  onChangeLanguage,
  onBlur,
}: {
  language: string;
  onChangeLanguage: (language: string) => void;
  onBlur?: () => void;
}) {
  const { t } = useTranslation();
  const ref = useRef<HTMLDivElement>(null);
  const [open, setOpen] = useState(false);
  const [search, setSearch] = useState('');

  const searchRef = useRef<HTMLDivElement>(null);
  const scrollRef = useRef<HTMLDivElement>(null);
  const options: KeyboardNavigationOption[] = useMemo(() => {
    return supportLanguage
      .map((item) => ({
        key: item.id,
        content: item.title,
      }))
      .filter((item) => {
        return item.content?.toLowerCase().includes(search.toLowerCase());
      });
  }, [search]);

  const handleClose = useCallback(() => {
    setOpen(false);
    setSearch('');
  }, []);

  const handleConfirm = useCallback(
    (key: string) => {
      onChangeLanguage(key);
      handleClose();
    },
    [onChangeLanguage, handleClose]
  );

  useEffect(() => {
    const element = ref.current;

    if (!element) return;
    const handleKeyDown = (e: KeyboardEvent) => {
      e.stopPropagation();
      e.preventDefault();

      if (e.key === 'Enter') {
        setOpen(true);
        return;
      }

      onBlur?.();
    };

    element.addEventListener('keydown', handleKeyDown);

    return () => {
      element.removeEventListener('keydown', handleKeyDown);
    };
  }, [onBlur]);

  const { paperHeight, transformOrigin, anchorOrigin, isEntered } = usePopoverAutoPosition({
    initialPaperWidth: 200,
    initialPaperHeight: 220,
    anchorEl: ref.current,
    initialAnchorOrigin: initialOrigin.anchorOrigin,
    initialTransformOrigin: initialOrigin.transformOrigin,
    open,
  });

  return (
    <>
      <TextField
        ref={ref}
        size={'small'}
        variant={'standard'}
        sx={{
          '& .MuiInputBase-root, & .MuiInputBase-input': {
            userSelect: 'none',
          },
        }}
        className={'w-[150px]'}
        value={language}
        onClick={() => {
          setOpen(true);
        }}
        InputProps={{
          readOnly: true,
        }}
        placeholder={t('document.codeBlock.language.placeholder')}
        label={t('document.codeBlock.language.label')}
      />

      {open && (
        <Popover
          disableAutoFocus={true}
          disableRestoreFocus={true}
          anchorOrigin={anchorOrigin}
          transformOrigin={transformOrigin}
          anchorEl={ref.current}
          keepMounted={false}
          open={open && isEntered}
          onClose={handleClose}
        >
          <div
            style={{
              height: paperHeight,
            }}
            className={'flex max-h-[220px] w-[200px] flex-col overflow-hidden py-2'}
          >
            <TextField
              ref={searchRef}
              value={search}
              autoComplete={'off'}
              spellCheck={false}
              autoCorrect={'off'}
              onChange={(e) => setSearch(e.target.value)}
              size={'small'}
              autoFocus={true}
              variant={'standard'}
              className={'px-2 text-xs'}
              placeholder={t('search.label')}
            />
            <div ref={scrollRef} className={'flex-1 overflow-y-auto overflow-x-hidden'}>
              <KeyboardNavigation
                disableFocus={true}
                focusRef={searchRef}
                onConfirm={handleConfirm}
                defaultFocusedKey={language}
                scrollRef={scrollRef}
                options={options}
                onEscape={handleClose}
              />
            </div>
          </div>
        </Popover>
      )}
    </>
  );
}

export default SelectLanguage;
