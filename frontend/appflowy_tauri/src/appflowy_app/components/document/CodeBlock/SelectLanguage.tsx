import React, { useCallback } from 'react';
import MenuItem from '@mui/material/MenuItem';
import FormControl from '@mui/material/FormControl';
import Select, { SelectChangeEvent } from '@mui/material/Select';
import { updateNodeDataThunk } from '$app_reducers/document/async-actions';
import { useAppDispatch } from '$app/stores/store';
import { supportLanguage } from '$app/constants/document/code';
import { useSubscribeDocument } from '$app/components/document/_shared/SubscribeDoc.hooks';
import { useTranslation } from 'react-i18next';

function SelectLanguage({ id, language }: { id: string; language: string }) {
  const dispatch = useAppDispatch();
  const { controller } = useSubscribeDocument();
  const { t } = useTranslation();
  const onLanguageSelect = useCallback(
    (event: SelectChangeEvent) => {
      if (!controller) return;
      const language = event.target.value;

      dispatch(
        updateNodeDataThunk({
          id,
          controller,
          data: {
            language,
          },
        })
      );
    },
    [controller, dispatch, id]
  );

  return (
    <FormControl variant='standard'>
      <Select
        className={'h-[28px] w-[150px]'}
        value={language || 'javascript'}
        onChange={onLanguageSelect}
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
