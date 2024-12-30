import { NumberFilter, NumberFilterCondition } from '@/application/database-yjs';
import React, { useMemo } from 'react';
import { useTranslation } from 'react-i18next';

function NumberFilterContentOverview({ filter }: { filter: NumberFilter }) {
  const { t } = useTranslation();

  const value = useMemo(() => {
    if (!filter.content) {
      return '';
    }

    const content = parseInt(filter.content);

    switch (filter.condition) {
      case NumberFilterCondition.Equal:
        return `= ${content}`;
      case NumberFilterCondition.NotEqual:
        return `!= ${content}`;
      case NumberFilterCondition.GreaterThan:
        return `> ${content}`;
      case NumberFilterCondition.GreaterThanOrEqualTo:
        return `>= ${content}`;
      case NumberFilterCondition.LessThan:
        return `< ${content}`;
      case NumberFilterCondition.LessThanOrEqualTo:
        return `<= ${content}`;
      case NumberFilterCondition.NumberIsEmpty:
        return t('grid.textFilter.isEmpty');
      case NumberFilterCondition.NumberIsNotEmpty:
        return t('grid.textFilter.isNotEmpty');
    }
  }, [filter.condition, filter.content, t]);

  return <>{value}</>;
}

export default NumberFilterContentOverview;
