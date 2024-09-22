import { YjsDatabaseKey } from '@/application/types';
import {
  CheckboxFilterCondition,
  ChecklistFilterCondition,
  FieldType,
  Filter,
  SelectOptionFilter,
  useFieldSelector,
} from '@/application/database-yjs';
import DateFilterContentOverview from '@/components/database/components/filters/overview/DateFilterContentOverview';
import NumberFilterContentOverview from '@/components/database/components/filters/overview/NumberFilterContentOverview';
import SelectFilterContentOverview from '@/components/database/components/filters/overview/SelectFilterContentOverview';
import TextFilterContentOverview from '@/components/database/components/filters/overview/TextFilterContentOverview';
import React, { useMemo } from 'react';
import { useTranslation } from 'react-i18next';

export function FilterContentOverview({ filter }: { filter: Filter }) {
  const { field } = useFieldSelector(filter?.fieldId);
  const fieldType = Number(field?.get(YjsDatabaseKey.type)) as FieldType;
  const { t } = useTranslation();

  return useMemo(() => {
    if (!field) return null;
    switch (fieldType) {
      case FieldType.RichText:
      case FieldType.URL:
        return <TextFilterContentOverview filter={filter} />;
      case FieldType.Number:
        return <NumberFilterContentOverview filter={filter} />;
      case FieldType.DateTime:
      case FieldType.LastEditedTime:
      case FieldType.CreatedTime:
        return <DateFilterContentOverview filter={filter} />;
      case FieldType.SingleSelect:
      case FieldType.MultiSelect:
        return <SelectFilterContentOverview field={field} filter={filter as SelectOptionFilter} />;
      case FieldType.Checkbox:
        return (
          <>
            : {t('grid.checkboxFilter.choicechipPrefix.is')}{' '}
            {filter.condition === CheckboxFilterCondition.IsChecked
              ? t('grid.checkboxFilter.isChecked')
              : t('grid.checkboxFilter.isUnchecked')}
          </>
        );
      case FieldType.Checklist:
        return (
          <>
            :{' '}
            {filter.condition === ChecklistFilterCondition.IsComplete
              ? t('grid.checklistFilter.isComplete')
              : t('grid.checklistFilter.isIncomplted')}
          </>
        );
      default:
        return null;
    }
  }, [field, fieldType, filter, t]);
}
