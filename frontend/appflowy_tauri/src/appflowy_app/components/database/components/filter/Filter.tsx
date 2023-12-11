import React, { FC, useMemo, useState } from 'react';
import {
  Filter as FilterType,
  Field as FieldData,
  UndeterminedFilter,
  TextFilterData,
  SelectFilterData,
  NumberFilterData,
  CheckboxFilterData,
  ChecklistFilterData,
  DateFilterData,
} from '$app/components/database/application';
import { Chip, Popover } from '@mui/material';
import { Property } from '$app/components/database/components/property';
import { ReactComponent as DropDownSvg } from '$app/assets/dropdown.svg';
import TextFilter from './text_filter/TextFilter';
import { FieldType } from '@/services/backend';
import FilterActions from '$app/components/database/components/filter/FilterActions';
import { updateFilter } from '$app/components/database/application/filter/filter_service';
import { useViewId } from '$app/hooks';
import SelectFilter from './select_filter/SelectFilter';

import DateFilter from '$app/components/database/components/filter/date_filter/DateFilter';
import FilterConditionSelect from '$app/components/database/components/filter/FilterConditionSelect';

interface Props {
  filter: FilterType;
  field: FieldData;
}

interface FilterComponentProps {
  filter: FilterType;
  field: FieldData;
  onChange: (data: UndeterminedFilter['data']) => void;
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
      data,
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

  return (
    <>
      <Chip
        clickable
        variant='outlined'
        label={
          <div className={'flex items-center justify-center'}>
            <Property field={field} />
            <DropDownSvg className={'ml-1.5 h-8 w-8'} />
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
          {Component && <Component filter={filter} field={field} onChange={onDataChange} />}
        </Popover>
      )}
    </>
  );
}

export default Filter;
