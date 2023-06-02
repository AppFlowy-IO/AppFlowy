import React, { useCallback, useContext } from 'react';
import MenuItem from '@mui/material/MenuItem';
import FormControl from '@mui/material/FormControl';
import Select, { SelectChangeEvent } from '@mui/material/Select';
import { updateNodeDataThunk } from '$app_reducers/document/async-actions';
import { useAppDispatch } from '$app/stores/store';
import { DocumentControllerContext } from '$app/stores/effects/document/document_controller';
import { supportLanguage } from '$app/constants/document/code';

function SelectLanguage({ id, language }: { id: string; language: string }) {
  const dispatch = useAppDispatch();
  const controller = useContext(DocumentControllerContext);

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
        label='Language'
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
