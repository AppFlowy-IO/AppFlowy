import React, { useCallback } from 'react';
import { MenuItem, SelectProps, FormControl } from '@mui/material';
import Select from '@mui/material/Select';
import { TextFilterConditionPB } from '@/services/backend';
import { useTranslation } from 'react-i18next';

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
    <FormControl size={'small'} variant={'standard'}>
      <Select {...props}>
        {TextFilterConditions.map((value) => {
          return (
            <MenuItem key={value} value={value}>
              {getText(value)}
            </MenuItem>
          );
        })}
      </Select>
    </FormControl>
  );
}

export default TextFilterConditionSelect;
