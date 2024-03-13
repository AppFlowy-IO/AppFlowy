import React, { useCallback, useMemo, useRef, useState } from 'react';
import { SelectOptionItem } from '$app/components/database/components/field_types/select/select_cell_actions/SelectOptionItem';
import { cellService, SelectCell as SelectCellType, SelectField, SelectTypeOption } from '$app/application/database';
import { useViewId } from '$app/hooks';
import {
  createSelectOption,
  insertOrUpdateSelectOption,
} from '$app/application/database/field/select_option/select_option_service';
import { FieldType } from '@/services/backend';
import { useTypeOption } from '$app/components/database';
import SearchInput from './SearchInput';
import { useTranslation } from 'react-i18next';
import KeyboardNavigation, {
  KeyboardNavigationOption,
} from '$app/components/_shared/keyboard_navigation/KeyboardNavigation';
import { Tag } from '$app/components/database/components/field_types/select/Tag';

const CREATE_OPTION_KEY = 'createOption';

function SelectCellActions({
  field,
  cell,
  onUpdated,
  onClose,
}: {
  field: SelectField;
  cell: SelectCellType;
  onUpdated?: () => void;
  onClose?: () => void;
}) {
  const { t } = useTranslation();
  const rowId = cell?.rowId;
  const viewId = useViewId();
  const typeOption = useTypeOption<SelectTypeOption>(field.id);
  const options = useMemo(() => typeOption.options ?? [], [typeOption.options]);
  const scrollRef = useRef<HTMLDivElement>(null);
  const inputRef = useRef<HTMLInputElement>(null);
  const selectedOptionIds = useMemo(() => cell?.data?.selectedOptionIds ?? [], [cell]);
  const [newOptionName, setNewOptionName] = useState('');

  const filteredOptions: KeyboardNavigationOption[] = useMemo(() => {
    const result = options
      .filter((option) => {
        return option.name.toLowerCase().includes(newOptionName.toLowerCase());
      })
      .map((option) => ({
        key: option.id,
        content: (
          <SelectOptionItem
            isSelected={selectedOptionIds?.includes(option.id)}
            fieldId={cell?.fieldId || ''}
            option={option}
          />
        ),
      }));

    if (result.length === 0 && newOptionName) {
      result.push({
        key: CREATE_OPTION_KEY,
        content: <Tag size='small' label={newOptionName} />,
      });
    }

    return result;
  }, [newOptionName, options, selectedOptionIds, cell?.fieldId]);

  const shouldCreateOption = filteredOptions.length === 1 && filteredOptions[0].key === 'createOption';

  const updateCell = useCallback(
    async (optionIds: string[]) => {
      if (!cell || !rowId) return;
      const deleteOptionIds = selectedOptionIds?.filter((id) => optionIds.find((cur) => cur === id) === undefined);

      await cellService.updateSelectCell(viewId, rowId, field.id, {
        insertOptionIds: optionIds,
        deleteOptionIds,
      });
      onUpdated?.();
    },
    [cell, field.id, onUpdated, rowId, selectedOptionIds, viewId]
  );

  const createOption = useCallback(async () => {
    const option = await createSelectOption(viewId, field.id, newOptionName);

    if (!option) return;
    await insertOrUpdateSelectOption(viewId, field.id, [option]);
    setNewOptionName('');
    return option;
  }, [viewId, field.id, newOptionName]);

  const onConfirm = useCallback(
    async (key: string) => {
      let optionId = key;

      if (key === CREATE_OPTION_KEY) {
        const option = await createOption();

        optionId = option?.id || '';
      }

      if (!optionId) return;

      if (field.type === FieldType.SingleSelect) {
        const newOptionIds = [optionId];

        if (selectedOptionIds?.includes(optionId)) {
          newOptionIds.pop();
        }

        void updateCell(newOptionIds);
        return;
      }

      let newOptionIds = [];

      if (!selectedOptionIds) {
        newOptionIds.push(optionId);
      } else {
        const isSelected = selectedOptionIds.includes(optionId);

        if (isSelected) {
          newOptionIds = selectedOptionIds.filter((id) => id !== optionId);
        } else {
          newOptionIds = [...selectedOptionIds, optionId];
        }
      }

      void updateCell(newOptionIds);
    },
    [createOption, field.type, selectedOptionIds, updateCell]
  );

  return (
    <div className={'flex h-full flex-col overflow-hidden'}>
      <SearchInput inputRef={inputRef} setNewOptionName={setNewOptionName} newOptionName={newOptionName} />

      {filteredOptions.length > 0 && (
        <div className='mx-4 mb-2 mt-4 text-xs'>
          {shouldCreateOption ? t('grid.selectOption.createNew') : t('grid.selectOption.orSelectOne')}
        </div>
      )}

      <div ref={scrollRef} className={'mx-1 flex-1 overflow-y-auto overflow-x-hidden px-1'}>
        <KeyboardNavigation
          scrollRef={scrollRef}
          focusRef={inputRef}
          options={filteredOptions}
          disableFocus={true}
          onConfirm={onConfirm}
          onEscape={onClose}
          itemStyle={{
            borderRadius: '4px',
          }}
          renderNoResult={() => null}
        />
      </div>
    </div>
  );
}

export default SelectCellActions;
