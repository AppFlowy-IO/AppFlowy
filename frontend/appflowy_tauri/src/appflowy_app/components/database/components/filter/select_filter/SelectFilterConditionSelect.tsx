import React, { useCallback } from 'react';
import { SelectProps } from '@mui/material';

import { FieldType, SelectOptionConditionPB } from '@/services/backend';
import { useTranslation } from 'react-i18next';
import ConditionSelect from '$app/components/database/components/filter/ConditionSelect';

const SelectFilterConditions = Object.values(SelectOptionConditionPB).filter(
  (item) => typeof item !== 'string'
) as SelectOptionConditionPB[];

function SelectFilterConditionsSelect({
  fieldType,
  ...props
}: SelectProps & {
  fieldType: FieldType;
}) {
  const { t } = useTranslation();
  const getSingleSelectOptionText = useCallback(
    (type: SelectOptionConditionPB) => {
      switch (type) {
        case SelectOptionConditionPB.OptionIs:
          return t('grid.singleSelectOptionFilter.is');
        case SelectOptionConditionPB.OptionIsNot:
          return t('grid.singleSelectOptionFilter.isNot');
        case SelectOptionConditionPB.OptionIsEmpty:
          return t('grid.singleSelectOptionFilter.isEmpty');
        case SelectOptionConditionPB.OptionIsNotEmpty:
          return t('grid.singleSelectOptionFilter.isNotEmpty');
        default:
          return '';
      }
    },
    [t]
  );

  const getMultiSelectOptionText = useCallback(
    (type: SelectOptionConditionPB) => {
      switch (type) {
        case SelectOptionConditionPB.OptionIs:
          return t('grid.multiSelectOptionFilter.contains');
        case SelectOptionConditionPB.OptionIsNot:
          return t('grid.multiSelectOptionFilter.doesNotContain');
        case SelectOptionConditionPB.OptionIsEmpty:
          return t('grid.multiSelectOptionFilter.isEmpty');
        case SelectOptionConditionPB.OptionIsNotEmpty:
          return t('grid.multiSelectOptionFilter.isNotEmpty');
        default:
          return '';
      }
    },
    [t]
  );

  const getText = useCallback(
    (type: SelectOptionConditionPB) => {
      switch (fieldType) {
        case FieldType.SingleSelect:
          return getSingleSelectOptionText(type);
        case FieldType.MultiSelect:
          return getMultiSelectOptionText(type);
        default:
          return '';
      }
    },
    [fieldType, getSingleSelectOptionText, getMultiSelectOptionText]
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
