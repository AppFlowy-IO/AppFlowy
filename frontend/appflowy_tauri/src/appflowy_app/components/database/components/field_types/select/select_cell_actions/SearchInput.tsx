import React, { FormEvent, useCallback } from 'react';
import { ListSubheader, OutlinedInput } from '@mui/material';
import { t } from 'i18next';

function SearchInput({
  setNewOptionName,
  newOptionName,
  onEnter,
}: {
  newOptionName: string;
  setNewOptionName: (value: string) => void;
  onEnter: () => void;
}) {
  const handleInput = useCallback(
    (event: FormEvent) => {
      const value = (event.target as HTMLInputElement).value;

      setNewOptionName(value);
    },
    [setNewOptionName]
  );

  return (
    <ListSubheader className='flex'>
      <OutlinedInput
        size='small'
        autoFocus={true}
        value={newOptionName}
        onInput={handleInput}
        onKeyDown={(e) => {
          if (e.key === 'Enter') {
            onEnter();
          }
        }}
        placeholder={t('grid.selectOption.searchOrCreateOption')}
      />
    </ListSubheader>
  );
}

export default SearchInput;
