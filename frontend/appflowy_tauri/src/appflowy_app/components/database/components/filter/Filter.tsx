import React, { FC, useMemo, useState } from 'react';
import {
  CheckboxFilterData,
  ChecklistFilterData,
  DateFilterData,
  Field as FieldData,
  Filter as FilterType,
  NumberFilterData,
  SelectFilterData,
  TextFilterData,
  UndeterminedFilter,
} from '$app/application/database';
import { Chip, Popover } from '@mui/material';
import { Property } from '$app/components/database/components/property';
import { ReactComponent as DropDownSvg } from '$app/assets/dropdown.svg';
import TextFilter from './text_filter/TextFilter';
import { CheckboxFilterConditionPB, ChecklistFilterConditionPB, FieldType } from '@/services/backend';
import FilterActions from '$app/components/database/components/filter/FilterActions';
import { updateFilter } from '$app/application/database/filter/filter_service';
import { useViewId } from '$app/hooks';
import SelectFilter from './select_filter/SelectFilter';

import DateFilter from '$app/components/database/components/filter/date_filter/DateFilter';
import FilterConditionSelect from '$app/components/database/components/filter/FilterConditionSelect';
import TextFilterValue from '$app/components/database/components/filter/text_filter/TextFilterValue';
import SelectFilterValue from '$app/components/database/components/filter/select_filter/SelectFilterValue';
import NumberFilterValue from '$app/components/database/components/filter/number_filter/NumberFilterValue';
import { useTranslation } from 'react-i18next';
import DateFilterValue from '$app/components/database/components/filter/date_filter/DateFilterValue';

interface Props {
  filter: FilterType;
  field: FieldData;
}

interface FilterComponentProps {
  filter: FilterType;
  field: FieldData;
  onChange: (data: UndeterminedFilter['data']) => void;
  onClose?: () => void;
}

type FilterComponent = FC<FilterComponentProps>;
const getFilterComponent = (field: FieldData) => {
  switch (field.type) {
    case FieldType.RichText:
    case FieldType.URL:
    case FieldType.Number:
      return TextFilter as FilterComponent;
    case FieldType.SingleSelect:
    case FieldType.MultiSelect:
      return SelectFilter as FilterComponent;

    case FieldType.DateTime:
    case FieldType.LastEditedTime:
    case FieldType.CreatedTime:
      return DateFilter as FilterComponent;
    default:
      return null;
  }
};

function Filter({ filter, field }: Props) {
  const viewId = useViewId();
  const { t } = useTranslation();
  const [anchorEl, setAnchorEl] = useState<null | HTMLElement>(null);
  const open = Boolean(anchorEl);
  const handleClick = (e: React.MouseEvent<HTMLElement>) => {
    setAnchorEl(e.currentTarget);
  };

  const handleClose = () => {
    setAnchorEl(null);
  };

  const onDataChange = async (data: UndeterminedFilter['data']) => {
    const newFilter = {
      ...filter,
      data: {
        ...(filter.data || {}),
        ...data,
      },
    } as UndeterminedFilter;

    try {
      await updateFilter(viewId, newFilter);
    } catch (e) {
      // toast.error(e.message);
    }
  };

  const Component = getFilterComponent(field);

  const condition = useMemo(() => {
    switch (field.type) {
      case FieldType.RichText:
      case FieldType.URL:
        return (filter.data as TextFilterData).condition;
      case FieldType.SingleSelect:
      case FieldType.MultiSelect:
        return (filter.data as SelectFilterData).condition;
      case FieldType.Number:
        return (filter.data as NumberFilterData).condition;
      case FieldType.Checkbox:
        return (filter.data as CheckboxFilterData).condition;
      case FieldType.Checklist:
        return (filter.data as ChecklistFilterData).condition;
      case FieldType.DateTime:
      case FieldType.LastEditedTime:
      case FieldType.CreatedTime:
        return (filter.data as DateFilterData).condition;
      default:
        return;
    }
  }, [field, filter]);

  const conditionValue = useMemo(() => {
    switch (field.type) {
      case FieldType.RichText:
      case FieldType.URL:
        return <TextFilterValue data={filter.data as TextFilterData} />;
      case FieldType.SingleSelect:
      case FieldType.MultiSelect:
        return <SelectFilterValue data={filter.data as SelectFilterData} fieldId={field.id} />;
      case FieldType.Number:
        return <NumberFilterValue data={filter.data as NumberFilterData} />;
      case FieldType.Checkbox:
        return (filter.data as CheckboxFilterData).condition === CheckboxFilterConditionPB.IsChecked
          ? t('grid.checkboxFilter.isChecked')
          : t('grid.checkboxFilter.isUnchecked');
      case FieldType.Checklist:
        return (filter.data as ChecklistFilterData).condition === ChecklistFilterConditionPB.IsComplete
          ? t('grid.checklistFilter.isComplete')
          : t('grid.checklistFilter.isIncomplted');
      case FieldType.DateTime:
      case FieldType.LastEditedTime:
      case FieldType.CreatedTime:
        return <DateFilterValue data={filter.data as DateFilterData} />;
      default:
        return '';
    }
  }, [field.id, field.type, filter.data, t]);

  return (
    <>
      <Chip
        clickable
        variant='outlined'
        label={
          <div className={'flex items-center justify-between gap-1'}>
            <Property className={'flex flex-1 items-center'} field={field} />
            <span className={'max-w-[120px] truncate'}>{conditionValue}</span>
            <DropDownSvg className={'h-6 w-6'} />
          </div>
        }
        onClick={handleClick}
      />
      {condition !== undefined && open && (
        <Popover
          anchorOrigin={{
            vertical: 'bottom',
            horizontal: 'center',
          }}
          transformOrigin={{
            vertical: 'top',
            horizontal: 'center',
          }}
          open={open}
          anchorEl={anchorEl}
          onClose={handleClose}
          keepMounted={false}
          onKeyDown={(e) => {
            if (e.key === 'Escape') {
              e.preventDefault();
              e.stopPropagation();
              handleClose();
            }
          }}
        >
          <div className={'flex items-center justify-between'}>
            <FilterConditionSelect
              name={field.name}
              condition={condition}
              fieldType={field.type}
              onChange={(condition) => {
                void onDataChange({
                  condition,
                });
              }}
            />
            <FilterActions filter={filter} />
          </div>
          {Component && <Component onClose={handleClose} filter={filter} field={field} onChange={onDataChange} />}
        </Popover>
      )}
    </>
  );
}

export default Filter;
