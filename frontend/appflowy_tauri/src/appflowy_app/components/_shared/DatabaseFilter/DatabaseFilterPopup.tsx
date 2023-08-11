import { t } from 'i18next';
import AddSvg from '../../_shared/svg/AddSvg';
import { useAppSelector } from '$app/stores/store';
import { MouseEventHandler, useMemo, useState } from 'react';
import { DatabaseFilterItem } from '$app/components/_shared/DatabaseFilter/DatabaseFilterItem';
import { IDatabaseFilter, TDatabaseOperators } from '$app_reducers/database/slice';
import { FilterController } from '$app/stores/effects/database/filter/filter_controller';
import {
  CheckboxFilterPB,
  FieldType,
  SelectOptionConditionPB,
  SelectOptionFilterPB,
  TextFilterConditionPB,
  TextFilterPB,
} from '@/services/backend';

export const DatabaseFilterPopup = ({
  filterController,
  onOutsideClick,
}: {
  filterController: FilterController;
  onOutsideClick: () => void;
}) => {
  // stores
  const filtersStore = useAppSelector((state) => state.database.filters);

  // local copy to prevent jitter when adding new filter
  const [filters, setFilters] = useState<(IDatabaseFilter | null)[]>(filtersStore);
  const [showBlankFilter, setShowBlankFilter] = useState(filtersStore.length === 0);

  const onAddClick: MouseEventHandler = () => {
    setShowBlankFilter(true);
  };

  const transformOperator: (
    operator: TDatabaseOperators,
    type: FieldType
  ) => TextFilterConditionPB | SelectOptionConditionPB = (operator, type) => {
    switch (type) {
      case FieldType.RichText:
        switch (operator) {
          case 'contains':
            return TextFilterConditionPB.Contains;
          case 'doesNotContain':
            return TextFilterConditionPB.DoesNotContain;
          case 'endsWith':
            return TextFilterConditionPB.EndsWith;
          case 'startWith':
            return TextFilterConditionPB.StartsWith;
          case 'is':
            return TextFilterConditionPB.Is;
          case 'isNot':
            return TextFilterConditionPB.IsNot;
          case 'isEmpty':
            return TextFilterConditionPB.TextIsEmpty;
          case 'isNotEmpty':
            return TextFilterConditionPB.TextIsNotEmpty;
          default:
            return TextFilterConditionPB.Is;
        }

      case FieldType.SingleSelect:
      case FieldType.MultiSelect:
        switch (operator) {
          case 'is':
          case 'contains':
            return SelectOptionConditionPB.OptionIs;
          case 'isNot':
          case 'doesNotContain':
            return SelectOptionConditionPB.OptionIsNot;
          case 'isEmpty':
            return SelectOptionConditionPB.OptionIsEmpty;
          case 'isNotEmpty':
            return SelectOptionConditionPB.OptionIsNotEmpty;
          default:
            return SelectOptionConditionPB.OptionIs;
        }

      default:
        return TextFilterConditionPB.Is;
    }
  };

  const onSaveFilterItem = async (filter: IDatabaseFilter) => {
    let val: TextFilterPB | SelectOptionFilterPB | CheckboxFilterPB;

    switch (filter.fieldType) {
      case FieldType.RichText:
        val = new TextFilterPB({
          condition: transformOperator(filter.operator, filter.fieldType) as TextFilterConditionPB,
          content: filter.value as string,
        });
        break;
      case FieldType.SingleSelect:
      case FieldType.MultiSelect:
        val = new SelectOptionFilterPB({
          condition: transformOperator(filter.operator, filter.fieldType) as SelectOptionConditionPB,
          option_ids: filter.value as string[],
        });
        break;
      default:
        val = new TextFilterPB({
          condition: transformOperator('is', FieldType.RichText) as TextFilterConditionPB,
          content: '',
        });
        break;
    }

    let updatedFilter = filter;

    if (filter.id) {
      await filterController.updateFilter(filter.id, filter.fieldId, filter.fieldType, val);
    } else {
      const newId = await filterController.addFilter(filter.fieldId, filter.fieldType, val);

      updatedFilter = { ...filter, id: newId };
    }

    const index = filters.findIndex((f) => f?.fieldId === filter.fieldId);

    if (index === -1) {
      setFilters([...filters, updatedFilter]);
    } else {
      setFilters([...filters.slice(0, index), updatedFilter, ...filters.slice(index + 1)]);
    }

    setShowBlankFilter(false);
  };

  const onDeleteFilterItem = async (filter: IDatabaseFilter | null) => {
    if (!filter || !filter.id || !filter.fieldId) return;

    // add blank filter if no filters left
    if (filters.length === 1) {
      setShowBlankFilter(true);
    }

    await filterController.removeFilter(filter.fieldId, filter.fieldType, filter.id);

    // update local copy
    const index = filters.findIndex((f) => f?.fieldId === filter.fieldId);

    setFilters([...filters.slice(0, index), ...filters.slice(index + 1)]);
  };

  // null row represents new filter
  const rows = useMemo(() => (showBlankFilter ? filters.concat([null]) : filters), [filters, showBlankFilter]);

  return (
    <div
      className={'fixed inset-0 z-10 flex items-center justify-center overflow-y-auto backdrop-blur-sm'}
      onClick={onOutsideClick}
    >
      <div onClick={(e) => e.stopPropagation()} className='flex flex-col rounded-lg bg-bg-body shadow-md'>
        <div className='px-6 pt-6 text-sm text-text-caption'>{t('grid.settings.filter')}</div>

        <div className='flex flex-col gap-3 overflow-y-scroll px-6 py-6 text-sm'>
          {rows.map((filter, index: number) => (
            <DatabaseFilterItem
              data={filter}
              onSave={onSaveFilterItem}
              onDelete={() => onDeleteFilterItem(filter)}
              key={index}
              index={index}
            ></DatabaseFilterItem>
          ))}
        </div>

        <hr />

        <button
          onClick={onAddClick}
          className='flex cursor-pointer items-center gap-2 px-6 py-6 text-sm text-text-caption'
        >
          <div className='h-5 w-5'>
            <AddSvg />
          </div>
          {t('grid.settings.addFilter')}
        </button>
      </div>
    </div>
  );
};
