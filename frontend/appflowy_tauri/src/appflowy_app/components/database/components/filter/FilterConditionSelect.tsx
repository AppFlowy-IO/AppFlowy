import React, { useMemo } from 'react';
import ConditionSelect from './ConditionSelect';
import {
  CheckboxFilterConditionPB,
  ChecklistFilterConditionPB,
  DateFilterConditionPB,
  FieldType,
  NumberFilterConditionPB,
  SelectOptionFilterConditionPB,
  TextFilterConditionPB,
} from '@/services/backend';

import { useTranslation } from 'react-i18next';

function FilterConditionSelect({
  name,
  condition,
  fieldType,
  onChange,
}: {
  name: string;
  condition: number;
  fieldType: FieldType;
  onChange: (condition: number) => void;
}) {
  const { t } = useTranslation();
  const conditions = useMemo(() => {
    switch (fieldType) {
      case FieldType.RichText:
      case FieldType.URL:
        return [
          {
            value: TextFilterConditionPB.TextContains,
            text: t('grid.textFilter.contains'),
          },
          {
            value: TextFilterConditionPB.TextDoesNotContain,
            text: t('grid.textFilter.doesNotContain'),
          },
          {
            value: TextFilterConditionPB.TextStartsWith,
            text: t('grid.textFilter.startWith'),
          },
          {
            value: TextFilterConditionPB.TextEndsWith,
            text: t('grid.textFilter.endsWith'),
          },
          {
            value: TextFilterConditionPB.TextIs,
            text: t('grid.textFilter.is'),
          },
          {
            value: TextFilterConditionPB.TextIsNot,
            text: t('grid.textFilter.isNot'),
          },
          {
            value: TextFilterConditionPB.TextIsEmpty,
            text: t('grid.textFilter.isEmpty'),
          },
          {
            value: TextFilterConditionPB.TextIsNotEmpty,
            text: t('grid.textFilter.isNotEmpty'),
          },
        ];
      case FieldType.SingleSelect:
        return [
          {
            value: SelectOptionFilterConditionPB.OptionIs,
            text: t('grid.selectOptionFilter.is'),
          },
          {
            value: SelectOptionFilterConditionPB.OptionIsNot,
            text: t('grid.selectOptionFilter.isNot'),
          },
          {
            value: SelectOptionFilterConditionPB.OptionIsEmpty,
            text: t('grid.selectOptionFilter.isEmpty'),
          },
          {
            value: SelectOptionFilterConditionPB.OptionIsNotEmpty,
            text: t('grid.selectOptionFilter.isNotEmpty'),
          },
        ];
      case FieldType.MultiSelect:
        return [
          {
            value: SelectOptionFilterConditionPB.OptionIs,
            text: t('grid.selectOptionFilter.is'),
          },
          {
            value: SelectOptionFilterConditionPB.OptionIsNot,
            text: t('grid.selectOptionFilter.isNot'),
          },
          {
            value: SelectOptionFilterConditionPB.OptionContains,
            text: t('grid.selectOptionFilter.contains'),
          },
          {
            value: SelectOptionFilterConditionPB.OptionDoesNotContain,
            text: t('grid.selectOptionFilter.doesNotContain'),
          },
          {
            value: SelectOptionFilterConditionPB.OptionIsEmpty,
            text: t('grid.selectOptionFilter.isEmpty'),
          },
          {
            value: SelectOptionFilterConditionPB.OptionIsNotEmpty,
            text: t('grid.selectOptionFilter.isNotEmpty'),
          },
        ];
      case FieldType.Number:
        return [
          {
            value: NumberFilterConditionPB.Equal,
            text: '=',
          },
          {
            value: NumberFilterConditionPB.NotEqual,
            text: '!=',
          },
          {
            value: NumberFilterConditionPB.GreaterThan,
            text: '>',
          },
          {
            value: NumberFilterConditionPB.LessThan,
            text: '<',
          },
          {
            value: NumberFilterConditionPB.GreaterThanOrEqualTo,
            text: '>=',
          },
          {
            value: NumberFilterConditionPB.LessThanOrEqualTo,
            text: '<=',
          },
          {
            value: NumberFilterConditionPB.NumberIsEmpty,
            text: t('grid.textFilter.isEmpty'),
          },
          {
            value: NumberFilterConditionPB.NumberIsNotEmpty,
            text: t('grid.textFilter.isNotEmpty'),
          },
        ];
      case FieldType.Checkbox:
        return [
          {
            value: CheckboxFilterConditionPB.IsChecked,
            text: t('grid.checkboxFilter.isChecked'),
          },
          {
            value: CheckboxFilterConditionPB.IsUnChecked,
            text: t('grid.checkboxFilter.isUnchecked'),
          },
        ];
      case FieldType.Checklist:
        return [
          {
            value: ChecklistFilterConditionPB.IsComplete,
            text: t('grid.checklistFilter.isComplete'),
          },
          {
            value: ChecklistFilterConditionPB.IsIncomplete,
            text: t('grid.checklistFilter.isIncomplted'),
          },
        ];
      case FieldType.DateTime:
      case FieldType.LastEditedTime:
      case FieldType.CreatedTime:
        return [
          {
            value: DateFilterConditionPB.DateIs,
            text: t('grid.dateFilter.is'),
          },
          {
            value: DateFilterConditionPB.DateBefore,
            text: t('grid.dateFilter.before'),
          },
          {
            value: DateFilterConditionPB.DateAfter,
            text: t('grid.dateFilter.after'),
          },
          {
            value: DateFilterConditionPB.DateOnOrBefore,
            text: t('grid.dateFilter.onOrBefore'),
          },
          {
            value: DateFilterConditionPB.DateOnOrAfter,
            text: t('grid.dateFilter.onOrAfter'),
          },
          {
            value: DateFilterConditionPB.DateWithIn,
            text: t('grid.dateFilter.between'),
          },
          {
            value: DateFilterConditionPB.DateIsEmpty,
            text: t('grid.dateFilter.empty'),
          },
          {
            value: DateFilterConditionPB.DateIsNotEmpty,
            text: t('grid.dateFilter.notEmpty'),
          },
        ];
      default:
        return [];
    }
  }, [fieldType, t]);

  return (
    <div className={'flex items-center justify-between gap-[20px] px-4'}>
      <div className={'flex-1 text-sm text-text-caption'}>{name}</div>
      <ConditionSelect
        conditions={conditions}
        onChange={(e) => {
          onChange(e);
        }}
        value={condition}
      />
    </div>
  );
}

export default FilterConditionSelect;
