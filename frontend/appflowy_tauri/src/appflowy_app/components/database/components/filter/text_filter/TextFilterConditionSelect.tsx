import React, { useCallback } from 'react';
import { SelectProps } from '@mui/material';

import { TextFilterConditionPB } from '@/services/backend';
import { useTranslation } from 'react-i18next';
import ConditionSelect from '$app/components/database/components/filter/ConditionSelect';

const TextFilterConditions = Object.values(TextFilterConditionPB).filter(
  (item) => typeof item !== 'string'
) as TextFilterConditionPB[];

function TextFilterConditionSelect(props: SelectProps) {
  const { t } = useTranslation();
  const getText = useCallback(
    (type: TextFilterConditionPB) => {
      switch (type) {
        case TextFilterConditionPB.Contains:
          return t('grid.textFilter.contains');
        case TextFilterConditionPB.DoesNotContain:
          return t('grid.textFilter.doesNotContain');
        case TextFilterConditionPB.Is:
          return t('grid.textFilter.is');
        case TextFilterConditionPB.IsNot:
          return t('grid.textFilter.isNot');
        case TextFilterConditionPB.StartsWith:
          return t('grid.textFilter.startWith');
        case TextFilterConditionPB.EndsWith:
          return t('grid.textFilter.endsWith');
        case TextFilterConditionPB.TextIsEmpty:
          return t('grid.textFilter.isEmpty');
        case TextFilterConditionPB.TextIsNotEmpty:
          return t('grid.textFilter.isNotEmpty');
        default:
          return '';
      }
    },
    [t]
  );

  return (
    <ConditionSelect
      conditions={TextFilterConditions.map((condition) => ({
        value: condition,
        text: getText(condition),
      }))}
      {...props}
    />
  );
}

export default TextFilterConditionSelect;
