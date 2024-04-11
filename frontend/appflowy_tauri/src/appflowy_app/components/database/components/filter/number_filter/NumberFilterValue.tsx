import React, { useMemo } from 'react';
import { NumberFilterData } from '$app/application/database';
import { NumberFilterConditionPB } from '@/services/backend';
import { useTranslation } from 'react-i18next';

function NumberFilterValue({ data }: { data: NumberFilterData }) {
  const { t } = useTranslation();

  const value = useMemo(() => {
    if (!data.content) {
      return '';
    }

    const content = parseInt(data.content);

    switch (data.condition) {
      case NumberFilterConditionPB.Equal:
        return `= ${content}`;
      case NumberFilterConditionPB.NotEqual:
        return `!= ${content}`;
      case NumberFilterConditionPB.GreaterThan:
        return `> ${content}`;
      case NumberFilterConditionPB.GreaterThanOrEqualTo:
        return `>= ${content}`;
      case NumberFilterConditionPB.LessThan:
        return `< ${content}`;
      case NumberFilterConditionPB.LessThanOrEqualTo:
        return `<= ${content}`;
      case NumberFilterConditionPB.NumberIsEmpty:
        return t('grid.textFilter.isEmpty');
      case NumberFilterConditionPB.NumberIsNotEmpty:
        return t('grid.textFilter.isNotEmpty');
    }
  }, [data.condition, data.content, t]);

  return <>{value}</>;
}

export default NumberFilterValue;
