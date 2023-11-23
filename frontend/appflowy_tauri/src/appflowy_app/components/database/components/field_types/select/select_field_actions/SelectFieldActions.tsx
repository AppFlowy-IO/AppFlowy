import React from 'react';
import { useTranslation } from 'react-i18next';
import AddAnOption from '$app/components/database/components/field_types/select/select_field_actions/AddAnOption';
import Options from '$app/components/database/components/field_types/select/select_field_actions/Options';
import { SelectField } from '$app/components/database/application';
import { Divider } from '@mui/material';

function SelectFieldActions({ field }: { field: SelectField }) {
  const options = field.typeOption.options ?? [];
  const { t } = useTranslation();

  return (
    <>
      <div className={'flex flex-col px-3 pt-1'}>
        <div className={'mb-2 px-2 text-sm text-text-caption'}>{t('grid.field.optionTitle')}</div>
        <AddAnOption fieldId={field.id} />
        <Options fieldId={field.id} options={options} />
      </div>
      <Divider className={'my-2'} />
    </>
  );
}

export default SelectFieldActions;
