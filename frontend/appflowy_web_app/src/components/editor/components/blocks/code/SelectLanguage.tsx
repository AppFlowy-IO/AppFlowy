import { ReactComponent as SelectedIcon } from '@/assets/selected.svg';
import { Popover } from '@/components/_shared/popover';
import { supportLanguages } from '@/components/editor/components/blocks/code/constants';
import { createHotkey, HOT_KEY_NAME } from '@/utils/hotkeys';
import { Button, TextField } from '@mui/material';
import React, { useCallback, useEffect, useMemo, useRef, useState } from 'react';
import { useTranslation } from 'react-i18next';

function SelectLanguage ({
  readOnly,
  language = 'Auto',
  onChangeLanguage,
}: {
  readOnly?: boolean;
  language: string;
  onChangeLanguage: (language: string) => void;
}) {
  const { t } = useTranslation();
  const ref = useRef<HTMLButtonElement>(null);
  const [open, setOpen] = useState(false);
  const [search, setSearch] = useState('');
  const [selectLanguage, setSelectLanguage] = useState<string>(language);
  const searchRef = useRef<HTMLDivElement>(null);
  const scrollRef = useRef<HTMLDivElement>(null);
  const options = useMemo(() => {
    return supportLanguages
      .map((item) => ({
        key: item.id,
        content: item.title,
      }))
      .filter((item) => {
        return item.content?.toLowerCase().includes(search?.toLowerCase());
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
    [onChangeLanguage, handleClose],
  );

  const selectedLanguage = useMemo(() => {
    return supportLanguages.find((item) => item.id === language?.toLowerCase())?.title || 'Auto';
  }, [language]);

  useEffect(() => {
    if (!open) return;
    searchRef.current?.focus();
  }, [open]);

  useEffect(() => {
    const container = scrollRef.current;

    if (!container) return;

    const el = container.querySelector(`[data-key="${selectLanguage}"]`);

    if (!el) return;

    el.scrollIntoView({ block: 'nearest' });
  }, [selectLanguage]);

  return (
    <>
      <Button
        ref={ref}
        sx={{
          cursor: readOnly ? 'not-allowed' : 'pointer',
        }}
        size={'small'}
        color={'inherit'}
        className={'px-4'}
        variant={'text'}
        onClick={() => {
          if (readOnly) return;
          setOpen(true);
        }}
      >
        {selectedLanguage}
      </Button>

      <Popover
        disableAutoFocus={true}
        disableRestoreFocus={true}
        anchorEl={ref.current}
        open={open}
        onClose={handleClose}
      >
        <div
          className={'flex max-h-[520px] h-fit w-[200px] flex-col overflow-hidden py-2'}
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
            className={'px-3 py-1 text-xs'}
            placeholder={t('search.label')}
            onKeyDown={(e) => {
              if (createHotkey(HOT_KEY_NAME.ENTER)(e.nativeEvent)) {
                e.preventDefault();
                handleConfirm(selectLanguage);
              }

              if (createHotkey(HOT_KEY_NAME.UP)(e.nativeEvent)) {
                const index = options.findIndex((item) => item.key === selectLanguage);
                const prevIndex = (index - 1 + options.length) % options.length;

                setSelectLanguage(options[prevIndex].key);
              }

              if (createHotkey(HOT_KEY_NAME.DOWN)(e.nativeEvent)) {
                const index = options.findIndex((item) => item.key === selectLanguage);
                const nextIndex = (index + 1) % options.length;

                setSelectLanguage(options[nextIndex].key);
              }

            }}
          />
          <div
            ref={scrollRef}
            className={'flex-1 overflow-y-auto p-2 appflowy-scroller overflow-x-hidden'}
          >
            {options.map((item) => (
              <div
                data-key={item.key}
                key={item.key}
                onClick={() => handleConfirm(item.key)}
                className={`p-2 ${selectLanguage === item.key ? 'bg-fill-list-hover' : ''} text-sm rounded-[8px] flex justify-between cursor-pointer hover:bg-gray-100`}
              >
                <div className={'flex-1'}>{item.content}</div>

                {item.key === language && (
                  <SelectedIcon className={'w-4 h-4 ml-1 text-function-success'} />
                )}
              </div>
            ))}
          </div>
        </div>
      </Popover>
    </>
  );
}

export default SelectLanguage;
