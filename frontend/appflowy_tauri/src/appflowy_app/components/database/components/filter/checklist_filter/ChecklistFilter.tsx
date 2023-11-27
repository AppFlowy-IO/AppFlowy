import React from 'react';
import {
  Field,
  ChecklistFilter as ChecklistFilterType,
  ChecklistFilterData,
} from '$app/components/database/application';

import { ChecklistFilterConditionPB } from '@/services/backend';
import { useTranslation } from 'react-i18next';
import ConditionSelect from '$app/components/database/components/filter/ConditionSelect';

interface Props {
  filter: ChecklistFilterType;
  field: Field;
  onChange: (filterData: ChecklistFilterData) => void;
}
function ChecklistFilter({ filter, field, onChange }: Props) {
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
            value: ChecklistFilterConditionPB.IsComplete,
            text: t('grid.checklistFilter.isComplete'),
          },
          {
            value: ChecklistFilterConditionPB.IsIncomplete,
            text: t('grid.checklistFilter.isIncomplted'),
          },
        ]}
        value={filter.data.condition}
      />
    </div>
  );
}

export default ChecklistFilter;
