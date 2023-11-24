import React, { useCallback } from 'react';
import { SelectProps } from '@mui/material';

import { NumberFilterConditionPB } from '@/services/backend';
import { useTranslation } from 'react-i18next';
import ConditionSelect from '$app/components/database/components/filter/ConditionSelect';

const NumberFilterConditions = Object.values(NumberFilterConditionPB).filter(
  (item) => typeof item !== 'string'
) as NumberFilterConditionPB[];

function NumberFilterConditionSelect(props: SelectProps) {
  const { t } = useTranslation();
  const getText = useCallback(
    (type: NumberFilterConditionPB) => {
      switch (type) {
        case NumberFilterConditionPB.Equal:
          return '=';
        case NumberFilterConditionPB.NotEqual:
          return '!=';
        case NumberFilterConditionPB.GreaterThan:
          return '>';
        case NumberFilterConditionPB.LessThan:
          return '<';
        case NumberFilterConditionPB.GreaterThanOrEqualTo:
          return '>=';
        case NumberFilterConditionPB.LessThanOrEqualTo:
          return '<=';
        case NumberFilterConditionPB.NumberIsEmpty:
          return t('grid.textFilter.isEmpty');
        case NumberFilterConditionPB.NumberIsNotEmpty:
          return t('grid.textFilter.isNotEmpty');
        default:
          return '';
      }
    },
    [t]
  );

  return (
    <ConditionSelect
      conditions={NumberFilterConditions.map((condition) => ({
        value: condition,
        text: getText(condition),
      }))}
      {...props}
    />
  );
}

export default NumberFilterConditionSelect;
