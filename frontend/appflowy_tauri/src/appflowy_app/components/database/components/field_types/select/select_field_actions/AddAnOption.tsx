import React, { useMemo, useState } from 'react';
import Button from '@mui/material/Button';
import { useTranslation } from 'react-i18next';
import { ReactComponent as AddSvg } from '$app/assets/add.svg';
import { OutlinedInput } from '@mui/material';
import {
  createSelectOption,
  insertOrUpdateSelectOption,
} from '$app/application/database/field/select_option/select_option_service';
import { useViewId } from '$app/hooks';
import { SelectOption } from '$app/application/database';
import { notify } from '$app/components/_shared/notify';

function AddAnOption({ fieldId, options }: { fieldId: string; options: SelectOption[] }) {
  const viewId = useViewId();
  const { t } = useTranslation();
  const [edit, setEdit] = useState(false);
  const [newOptionName, setNewOptionName] = useState('');
  const exitEdit = () => {
    setNewOptionName('');
    setEdit(false);
  };

  const isOptionExist = useMemo(() => {
    return options.some((option) => option.name === newOptionName);
  }, [options, newOptionName]);

  const createOption = async () => {
    if (!newOptionName) return;
    if (isOptionExist) {
      notify.error(t('grid.field.optionAlreadyExist'));
      return;
    }

    const option = await createSelectOption(viewId, fieldId, newOptionName);

    if (!option) return;
    await insertOrUpdateSelectOption(viewId, fieldId, [option]);
    setNewOptionName('');
  };

  return edit ? (
    <OutlinedInput
      onBlur={exitEdit}
      autoFocus={true}
      spellCheck={false}
      onChange={(e) => {
        setNewOptionName(e.target.value);
      }}
      value={newOptionName}
      onKeyDown={(e) => {
        if (e.key === 'Enter') {
          e.stopPropagation();
          e.preventDefault();
          void createOption();
          return;
        }

        if (e.key === 'Escape') {
          e.stopPropagation();
          e.preventDefault();
          exitEdit();
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
