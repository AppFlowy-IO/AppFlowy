import React, { FormEvent, useCallback } from 'react';
import { OutlinedInput } from '@mui/material';
import { t } from 'i18next';

function SearchInput({
  setNewOptionName,
  newOptionName,
  onEnter,
  onEscape,
}: {
  newOptionName: string;
  setNewOptionName: (value: string) => void;
  onEnter: () => void;
  onEscape?: () => void;
}) {
  const handleInput = useCallback(
    (event: FormEvent) => {
      const value = (event.target as HTMLInputElement).value;

      setNewOptionName(value);
    },
    [setNewOptionName]
  );

  return (
    <OutlinedInput
      size='small'
      className={'mx-4'}
      autoFocus={true}
      value={newOptionName}
      onInput={handleInput}
      spellCheck={false}
      onKeyDown={(e) => {
        if (e.key === 'Enter') {
          onEnter();
        }

        if (e.key === 'Escape') {
          e.stopPropagation();
          e.preventDefault();
          onEscape?.();
        }
      }}
      placeholder={t('grid.selectOption.searchOrCreateOption')}
    />
  );
}

export default SearchInput;
