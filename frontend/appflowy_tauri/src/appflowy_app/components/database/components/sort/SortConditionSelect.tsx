import { t } from 'i18next';
import { FC } from 'react';
import { MenuItem, Select, SelectProps } from '@mui/material';
import { SortConditionPB } from '@/services/backend';

export const SortConditionSelect: FC<SelectProps<SortConditionPB>> = (props) => {
  return (
    <Select {...props}>
      <MenuItem value={SortConditionPB.Ascending}>{t('grid.sort.ascending')}</MenuItem>
      <MenuItem value={SortConditionPB.Descending}>{t('grid.sort.descending')}</MenuItem>
    </Select>
  );
};
