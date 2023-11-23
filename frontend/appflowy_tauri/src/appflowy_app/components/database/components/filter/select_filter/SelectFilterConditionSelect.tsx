import React, { useCallback } from 'react';
import { SelectProps } from '@mui/material';

import { SelectOptionConditionPB } from '@/services/backend';
import { useTranslation } from 'react-i18next';
import ConditionSelect from '$app/components/database/components/filter/ConditionSelect';

const SelectFilterConditions = Object.values(SelectOptionConditionPB).filter(
  (item) => typeof item !== 'string'
) as SelectOptionConditionPB[];

function SelectFilterConditionsSelect(props: SelectProps) {
  const { t } = useTranslation();
  const getText = useCallback(
    (type: SelectOptionConditionPB) => {
      switch (type) {
        case SelectOptionConditionPB.OptionIs:
          return t('grid.textFilter.is');
        case SelectOptionConditionPB.OptionIsNot:
          return t('grid.textFilter.isNot');
        case SelectOptionConditionPB.OptionIsEmpty:
          return t('grid.textFilter.isEmpty');
        case SelectOptionConditionPB.OptionIsNotEmpty:
          return t('grid.textFilter.isNotEmpty');
        default:
          return '';
      }
    },
    [t]
  );

  return (
    <ConditionSelect
      conditions={SelectFilterConditions.map((condition) => ({
        value: condition,
        text: getText(condition),
      }))}
      {...props}
    />
  );
}

export default SelectFilterConditionsSelect;
