import React, { useCallback } from 'react';
import { NumberField, NumberTypeOption, updateTypeOption } from '$app/components/database/application';
import { Divider } from '@mui/material';
import { useTranslation } from 'react-i18next';
import NumberFormatSelect from '$app/components/database/components/field_types/number/NumberFormatSelect';
import { NumberFormatPB } from '@/services/backend';
import { useViewId } from '$app/hooks';
import { useTypeOption } from '$app/components/database';

function NumberFieldActions({ field }: { field: NumberField }) {
  const viewId = useViewId();
  const { t } = useTranslation();
  const typeOption = useTypeOption<NumberTypeOption>(field.id);
  const onChange = useCallback(
    async (value: NumberFormatPB) => {
      await updateTypeOption(viewId, field.id, field.type, {
        format: value,
      });
    },
    [field.id, field.type, viewId]
  );

  return (
    <>
      <div className={'flex flex-col pr-3 pt-1'}>
        <div className={'mb-2 px-5 text-sm text-text-caption'}>{t('grid.field.format')}</div>
        <NumberFormatSelect value={typeOption.format || NumberFormatPB.Num} onChange={onChange} />
      </div>
      <Divider className={'my-2'} />
    </>
  );
}

export default NumberFieldActions;
