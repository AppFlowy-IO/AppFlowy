import React, { useCallback, useState } from 'react';
import TextField from '@mui/material/TextField';
import { useTranslation } from 'react-i18next';
import Button from '@mui/material/Button';

const urlPattern = /^(https?:\/\/)([^\s(["<,>/]*)(\/)[^\s[",><]*(.png|.jpg|.gif|.webm|.webp|.svg)(\?[^\s[",><]*)?$/;

export function EmbedLink({
  onDone,
  onEscape,
  defaultLink,
}: {
  defaultLink?: string;
  onDone?: (value: string) => void;
  onEscape?: () => void;
}) {
  const { t } = useTranslation();

  const [value, setValue] = useState(defaultLink ?? '');
  const [error, setError] = useState(false);

  const handleChange = useCallback(
    (e: React.ChangeEvent<HTMLInputElement>) => {
      const value = e.target.value;

      setValue(value);
      setError(!urlPattern.test(value));
    },
    [setValue, setError]
  );

  const handleKeyDown = useCallback(
    (e: React.KeyboardEvent) => {
      if (e.key === 'Enter' && !error && value) {
        e.preventDefault();
        e.stopPropagation();
        onDone?.(value);
      }

      if (e.key === 'Escape') {
        e.preventDefault();
        e.stopPropagation();
        onEscape?.();
      }
    },
    [error, onDone, onEscape, value]
  );

  return (
    <div tabIndex={0} onKeyDown={handleKeyDown} className={'flex flex-col items-center gap-4 px-4 pb-4'}>
      <TextField
        error={error}
        autoFocus
        onKeyDown={handleKeyDown}
        size={'small'}
        spellCheck={false}
        onChange={handleChange}
        helperText={error ? t('editor.incorrectLink') : ''}
        value={value}
        placeholder={t('document.imageBlock.embedLink.placeholder')}
        fullWidth
      />
      <Button variant={'contained'} className={'w-3/5'} onClick={() => onDone?.(value)} disabled={error || !value}>
        {t('document.imageBlock.embedLink.label')}
      </Button>
    </div>
  );
}

export default EmbedLink;
