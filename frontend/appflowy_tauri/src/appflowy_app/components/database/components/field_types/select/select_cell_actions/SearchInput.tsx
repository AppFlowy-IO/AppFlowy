import React, { FormEvent, useCallback } from 'react';
import { OutlinedInput } from '@mui/material';
import { useTranslation } from 'react-i18next';

function SearchInput({
  setNewOptionName,
  newOptionName,
  inputRef,
}: {
  newOptionName: string;
  setNewOptionName: (value: string) => void;
  inputRef?: React.RefObject<HTMLInputElement>;
}) {
  const { t } = useTranslation();
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
      inputRef={inputRef}
      value={newOptionName}
      onInput={handleInput}
      spellCheck={false}
      placeholder={t('grid.selectOption.searchOrCreateOption')}
    />
  );
}

export default SearchInput;
