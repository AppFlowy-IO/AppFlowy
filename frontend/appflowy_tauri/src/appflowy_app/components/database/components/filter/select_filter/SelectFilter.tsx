import React, { useMemo } from 'react';
import {
  SelectField,
  SelectFilter as SelectFilterType,
  SelectFilterData,
  SelectTypeOption,
} from '$app/components/database/application';
import { MenuItem, MenuList } from '@mui/material';
import { Tag } from '$app/components/database/components/field_types/select/Tag';
import { ReactComponent as SelectCheckSvg } from '$app/assets/database/select-check.svg';
import { SelectOptionConditionPB } from '@/services/backend';
import { useTypeOption } from '$app/components/database';

interface Props {
  filter: SelectFilterType;
  field: SelectField;
  onChange: (filterData: SelectFilterData) => void;
}

function SelectFilter({ filter, field, onChange }: Props) {
  const condition = filter.data.condition;
  const typeOption = useTypeOption<SelectTypeOption>(field.id);
  const options = useMemo(() => typeOption.options ?? [], [typeOption]);

  const showOptions =
    options.length > 0 &&
    condition !== SelectOptionConditionPB.OptionIsEmpty &&
    condition !== SelectOptionConditionPB.OptionIsNotEmpty;

  const handleChange = ({
    condition,
    optionIds,
  }: {
    condition?: SelectFilterData['condition'];
    optionIds?: SelectFilterData['optionIds'];
  }) => {
    onChange({
      condition: condition ?? filter.data.condition,
      optionIds: optionIds ?? filter.data.optionIds,
    });
  };

  const handleSelectOption = (optionId: string) => {
    const prev = filter.data.optionIds;
    let newOptionIds = [];

    if (!prev) {
      newOptionIds.push(optionId);
    } else {
      const isSelected = prev.includes(optionId);

      if (isSelected) {
        newOptionIds = prev.filter((id) => id !== optionId);
      } else {
        newOptionIds = [...prev, optionId];
      }
    }

    handleChange({
      condition,
      optionIds: newOptionIds,
    });
  };

  if (!showOptions) return null;

  return (
    <MenuList>
      {options?.map((option) => {
        const isSelected = filter.data.optionIds?.includes(option.id);

        return (
          <MenuItem
            className={'flex items-center justify-between px-2'}
            onClick={() => handleSelectOption(option.id)}
            key={option.id}
          >
            <Tag size='small' color={option.color} label={option.name} />
            {isSelected && <SelectCheckSvg />}
          </MenuItem>
        );
      })}
    </MenuList>
  );
}

export default SelectFilter;
