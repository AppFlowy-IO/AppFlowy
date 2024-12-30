import { TextFilter, TextFilterCondition } from '@/application/database-yjs';
import React, { useMemo } from 'react';
import { useTranslation } from 'react-i18next';

function TextFilterContentOverview({ filter }: { filter: TextFilter }) {
  const { t } = useTranslation();

  const value = useMemo(() => {
    if (!filter.content) return '';
    switch (filter.condition) {
      case TextFilterCondition.TextContains:
      case TextFilterCondition.TextIs:
        return `: ${filter.content}`;
      case TextFilterCondition.TextDoesNotContain:
      case TextFilterCondition.TextIsNot:
        return `: ${t('grid.textFilter.choicechipPrefix.isNot')} ${filter.content}`;
      case TextFilterCondition.TextStartsWith:
        return `: ${t('grid.textFilter.choicechipPrefix.startWith')} ${filter.content}`;
      case TextFilterCondition.TextEndsWith:
        return `: ${t('grid.textFilter.choicechipPrefix.endWith')} ${filter.content}`;
      case TextFilterCondition.TextIsEmpty:
        return `: ${t('grid.textFilter.choicechipPrefix.isEmpty')}`;
      case TextFilterCondition.TextIsNotEmpty:
        return `: ${t('grid.textFilter.choicechipPrefix.isNotEmpty')}`;
      default:
        return '';
    }
  }, [t, filter]);

  return <>{value}</>;
}

export default TextFilterContentOverview;
