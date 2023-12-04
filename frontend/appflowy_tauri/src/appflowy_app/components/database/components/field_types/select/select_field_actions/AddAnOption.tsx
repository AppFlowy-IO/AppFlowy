import React, { useState } from 'react';
import Button from '@mui/material/Button';
import { useTranslation } from 'react-i18next';
import { ReactComponent as AddSvg } from '$app/assets/add.svg';
import { OutlinedInput } from '@mui/material';
import {
  createSelectOption,
  insertOrUpdateSelectOption,
} from '$app/components/database/application/field/select_option/select_option_service';
import { useViewId } from '$app/hooks';

function AddAnOption({ fieldId }: { fieldId: string }) {
  const viewId = useViewId();
  const { t } = useTranslation();
  const [edit, setEdit] = useState(false);
  const [newOptionName, setNewOptionName] = useState('');
  const exitEdit = () => {
    setNewOptionName('');
    setEdit(false);
  };

  const createOption = async () => {
    const option = await createSelectOption(viewId, fieldId, newOptionName);

    if (!option) return;
    await insertOrUpdateSelectOption(viewId, fieldId, [option]);
    setNewOptionName('');
  };

  return edit ? (
    <OutlinedInput
      onBlur={exitEdit}
      autoFocus={true}
      onChange={(e) => {
        setNewOptionName(e.target.value);
      }}
      value={newOptionName}
      onKeyDown={(e) => {
        if (e.key === 'Enter') {
          void createOption();
        }
      }}
      className={'mx-2 mb-1'}
      placeholder={t('grid.selectOption.typeANewOption')}
      size='small'
    />
  ) : (
    <Button onClick={() => setEdit(true)} color={'inherit'} startIcon={<AddSvg />}>
      <div className={'w-full text-left'}>{t('grid.field.addSelectOption')}</div>
    </Button>
  );
}

export default AddAnOption;
