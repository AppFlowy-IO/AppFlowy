import React, { useRef } from 'react';
import { TextField } from '@mui/material';
import { useTranslation } from 'react-i18next';

function SelectLanguage({
  readOnly,
  language = 'json',
}: {
  readOnly?: boolean;
  language: string;
  onChangeLanguage: (language: string) => void;
  onBlur?: () => void;
}) {
  const { t } = useTranslation();
  const ref = useRef<HTMLDivElement>(null);

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
          if (readOnly) return;
        }}
        InputProps={{
          readOnly: true,
        }}
        placeholder={t('document.codeBlock.language.placeholder')}
        label={t('document.codeBlock.language.label')}
      />
    </>
  );
}

export default SelectLanguage;
