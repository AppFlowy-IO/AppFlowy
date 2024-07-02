import { InputAdornment, OutlinedInput } from '@mui/material';
import { debounce } from 'lodash-es';
import React from 'react';
import { ReactComponent as SearchIcon } from '@/assets/search.svg';
import { useTranslation } from 'react-i18next';

function SearchInput({ onSearch }: { onSearch: (value: string) => void }) {
  const [value, setValue] = React.useState('');

  const debounceSearch = React.useMemo(() => {
    return debounce((value: string) => {
      onSearch(value);
    }, 200);
  }, [onSearch]);
  const handleChange = (event: React.ChangeEvent<HTMLInputElement>) => {
    setValue(event.target.value);
    debounceSearch(event.target.value);
  };

  const { t } = useTranslation();

  return (
    <OutlinedInput
      spellCheck={false}
      startAdornment={
        <InputAdornment className={'text-text-caption'} position='start'>
          <SearchIcon className={'h-4 w-4'} />
        </InputAdornment>
      }
      onChange={handleChange}
      placeholder={t('search.label')}
      className={'h-[30px] w-full rounded-lg bg-bg-body'}
      value={value}
      size={'small'}
    />
  );
}

export default SearchInput;
