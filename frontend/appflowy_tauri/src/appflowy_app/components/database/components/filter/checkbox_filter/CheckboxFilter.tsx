import React from 'react';
import { Field, CheckboxFilter as CheckboxFilterType, CheckboxFilterData } from '$app/components/database/application';

import { CheckboxFilterConditionPB } from '@/services/backend';
import { useTranslation } from 'react-i18next';
import ConditionSelect from '$app/components/database/components/filter/ConditionSelect';

interface Props {
  filter: CheckboxFilterType;
  field: Field;
  onChange: (filterData: CheckboxFilterData) => void;
}
function CheckboxFilter({ filter, field, onChange }: Props) {
  const { t } = useTranslation();

  return (
    <div className={'flex w-[220px] items-center justify-between gap-[20px] p-2 pr-10'}>
      <div className={'flex-1 text-sm text-text-caption'}>{field.name}</div>
      <ConditionSelect
        onChange={(e) => {
          const value = Number(e.target.value);

          onChange({
            condition: value,
          });
        }}
        conditions={[
          {
            value: CheckboxFilterConditionPB.IsChecked,
            text: t('grid.checkboxFilter.isChecked'),
          },
          {
            value: CheckboxFilterConditionPB.IsUnChecked,
            text: t('grid.checkboxFilter.isUnchecked'),
          },
        ]}
        value={filter.data.condition}
      />
    </div>
  );
}

export default CheckboxFilter;
