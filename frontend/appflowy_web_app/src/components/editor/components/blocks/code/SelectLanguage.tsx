import { supportLanguages } from '@/components/editor/components/blocks/code/constants';
import React, { useCallback, useMemo, useRef, useState } from 'react';
import { Button, TextField } from '@mui/material';
import { useTranslation } from 'react-i18next';
import { PopoverOrigin } from '@mui/material/Popover/Popover';
import { Popover } from '@/components/_shared/popover';
import { ReactComponent as SelectedIcon } from '@/assets/selected.svg';

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

  const searchRef = useRef<HTMLDivElement>(null);
  const scrollRef = useRef<HTMLDivElement>(null);
  const options = useMemo(() => {
    return supportLanguages
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
    [onChangeLanguage, handleClose],
  );

  const selectedLanguage = useMemo(() => {
    return supportLanguages.find((item) => item.id === language.toLowerCase())?.title || 'Auto';
  }, [language]);

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
          />
          <div
            ref={scrollRef}
            className={'flex-1 overflow-y-auto p-2 appflowy-scroller overflow-x-hidden'}
          >
            {options.map((item) => (
              <div
                key={item.key}
                onClick={() => handleConfirm(item.key)}
                className={'p-2 text-sm rounded-[8px] flex justify-between cursor-pointer hover:bg-gray-100'}
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
