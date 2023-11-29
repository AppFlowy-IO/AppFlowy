import React, { FC, useState } from 'react';
import { Filter as FilterType, Field as FieldData, UndeterminedFilter } from '$app/components/database/application';
import { Chip, Popover } from '@mui/material';
import { Field } from '$app/components/database/components/field';
import { ReactComponent as DropDownSvg } from '$app/assets/dropdown.svg';
import TextFilter from './text_filter/TextFilter';
import { FieldType } from '@/services/backend';
import FilterActions from '$app/components/database/components/filter/FilterActions';
import { updateFilter } from '$app/components/database/application/filter/filter_service';
import { useViewId } from '$app/hooks';
import SelectFilter from './select_filter/SelectFilter';
import NumberFilter from '$app/components/database/components/filter/number_filter/NumberFilter';
import CheckboxFilter from '$app/components/database/components/filter/checkbox_filter/CheckboxFilter';
import ChecklistFilter from '$app/components/database/components/filter/checklist_filter/ChecklistFilter';
import DateFilter from '$app/components/database/components/filter/date_filter/DateFilter';

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
      return TextFilter as FilterComponent;
    case FieldType.SingleSelect:
    case FieldType.MultiSelect:
      return SelectFilter as FilterComponent;
    case FieldType.Number:
      return NumberFilter as FilterComponent;
    case FieldType.Checkbox:
      return CheckboxFilter as FilterComponent;
    case FieldType.Checklist:
      return ChecklistFilter as FilterComponent;
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

  return (
    <>
      <Chip
        clickable
        variant='outlined'
        label={
          <div className={'flex items-center justify-center'}>
            <Field field={field} />
            <DropDownSvg className={'ml-1.5 h-8 w-8'} />
          </div>
        }
        onClick={handleClick}
      />
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
        <div className={'relative'}>
          {Component && <Component filter={filter} field={field} onChange={onDataChange} />}
          <div className={'absolute right-0 top-0'}>
            <FilterActions filter={filter} />
          </div>
        </div>
      </Popover>
    </>
  );
}

export default Filter;
