import React from 'react';
import MenuItem from '@mui/material/MenuItem';
import FormControl from '@mui/material/FormControl';
import Select, { SelectChangeEvent } from '@mui/material/Select';
import { useTranslation } from 'react-i18next';
import { supportLanguage } from './constants';

function SelectLanguage({
  language,
  onChangeLanguage,
}: {
  language: string;
  onChangeLanguage: (language: string) => void;
}) {
  const { t } = useTranslation();

  return (
    <FormControl variant='standard'>
      <Select
        size={'small'}
        className={'h-[28px] w-[150px]'}
        value={language || 'javascript'}
        onChange={(event: SelectChangeEvent) => onChangeLanguage(event.target.value)}
        placeholder={t('document.codeBlock.language.placeholder')}
        label={t('document.codeBlock.language.label')}
      >
        {supportLanguage.map((item) => (
          <MenuItem key={item.id} value={item.id}>
            {item.title}
          </MenuItem>
        ))}
      </Select>
    </FormControl>
  );
}

export default SelectLanguage;
