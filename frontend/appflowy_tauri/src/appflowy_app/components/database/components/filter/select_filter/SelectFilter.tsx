import React, { useMemo, useRef } from 'react';
import {
  SelectField,
  SelectFilter as SelectFilterType,
  SelectFilterData,
  SelectTypeOption,
} from '$app/application/database';
import { Tag } from '$app/components/database/components/field_types/select/Tag';
import { ReactComponent as SelectCheckSvg } from '$app/assets/select-check.svg';
import { SelectOptionFilterConditionPB } from '@/services/backend';
import { useTypeOption } from '$app/components/database';
import KeyboardNavigation, {
  KeyboardNavigationOption,
} from '$app/components/_shared/keyboard_navigation/KeyboardNavigation';

interface Props {
  filter: SelectFilterType;
  field: SelectField;
  onChange: (filterData: SelectFilterData) => void;
  onClose?: () => void;
}

function SelectFilter({ onClose, filter, field, onChange }: Props) {
  const scrollRef = useRef<HTMLDivElement>(null);
  const condition = filter.data.condition;
  const typeOption = useTypeOption<SelectTypeOption>(field.id);
  const options: KeyboardNavigationOption[] = useMemo(() => {
    return (
      typeOption?.options?.map((option) => {
        return {
          key: option.id,
          content: (
            <div className={'flex w-full items-center justify-between px-2'}>
              <Tag size='small' color={option.color} label={option.name} />
              {filter.data.optionIds?.includes(option.id) && <SelectCheckSvg className={'text-content-blue-400'} />}
            </div>
          ),
        };
      }) ?? []
    );
  }, [filter.data.optionIds, typeOption?.options]);

  const showOptions =
    options.length > 0 &&
    condition !== SelectOptionFilterConditionPB.OptionIsEmpty &&
    condition !== SelectOptionFilterConditionPB.OptionIsNotEmpty;

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
    <div ref={scrollRef}>
      <KeyboardNavigation onEscape={onClose} scrollRef={scrollRef} options={options} onConfirm={handleSelectOption} />
    </div>
  );
}

export default SelectFilter;
