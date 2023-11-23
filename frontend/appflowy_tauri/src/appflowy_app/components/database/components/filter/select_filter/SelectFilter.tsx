import React, { useState } from 'react';
import { SelectField, SelectFilterData, SelectFilter as SelectFilterType } from '$app/components/database/application';
import { MenuItem, MenuList } from '@mui/material';
import SelectFilterConditionsSelect from '$app/components/database/components/filter/select_filter/SelectFilterConditionSelect';
import { Tag } from '$app/components/database/components/field_types/select/Tag';
import { ReactComponent as SelectCheckSvg } from '$app/assets/database/select-check.svg';

interface Props {
  filter: SelectFilterType;
  field: SelectField;
  onChange: (filterData: SelectFilterData) => void;
}

function SelectFilter({ filter, field, onChange }: Props) {
  const [selectedCondition, setSelectedCondition] = useState(filter.data.condition);
  const options = field.typeOption.options ?? [];

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
      condition: selectedCondition,
      optionIds: newOptionIds,
    });
  };

  return (
    <div className={'flex min-w-[200px] flex-col text-sm'}>
      <div className={'flex justify-between gap-[20px] p-2 pb-1 pr-10'}>
        <div className={'flex-1 text-text-caption'}>{field.name}</div>
        <SelectFilterConditionsSelect
          onChange={(e) => {
            const value = Number(e.target.value);

            setSelectedCondition(value);
            handleChange({
              condition: value,
            });
          }}
          value={selectedCondition}
        />
      </div>
      {options.length > 0 && (
        <>
          {options.map((option) => {
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
        </>
      )}
    </div>
  );
}

export default SelectFilter;
