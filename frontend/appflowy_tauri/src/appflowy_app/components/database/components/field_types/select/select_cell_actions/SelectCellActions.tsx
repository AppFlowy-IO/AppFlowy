import React, { useCallback, useMemo, useState } from 'react';
import { MenuItem } from '@mui/material';
import { t } from 'i18next';
import { CreateOption } from '$app/components/database/components/field_types/select/select_cell_actions/CreateOption';
import { SelectOptionItem } from '$app/components/database/components/field_types/select/select_cell_actions/SelectOptionItem';
import {
  cellService,
  SelectCell as SelectCellType,
  SelectField,
  SelectTypeOption,
} from '$app/components/database/application';
import { useViewId } from '$app/hooks';
import {
  createSelectOption,
  insertOrUpdateSelectOption,
} from '$app/components/database/application/field/select_option/select_option_service';
import { FieldType } from '@/services/backend';
import { useTypeOption } from '$app/components/database';
import SearchInput from './SearchInput';

function SelectCellActions({
  field,
  cell,
  onUpdated,
}: {
  field: SelectField;
  cell: SelectCellType;
  onUpdated?: () => void;
}) {
  const rowId = cell?.rowId;
  const viewId = useViewId();
  const typeOption = useTypeOption<SelectTypeOption>(field.id);
  const options = useMemo(() => typeOption.options ?? [], [typeOption.options]);

  const selectedOptionIds = useMemo(() => cell?.data?.selectedOptionIds ?? [], [cell]);
  const [newOptionName, setNewOptionName] = useState('');
  const filteredOptions = useMemo(
    () =>
      options.filter((option) => {
        return option.name.toLowerCase().includes(newOptionName.toLowerCase());
      }),
    [options, newOptionName]
  );

  const shouldCreateOption = !!newOptionName && filteredOptions.length === 0;

  const updateCell = useCallback(
    async (optionIds: string[]) => {
      if (!cell || !rowId) return;
      const prev = selectedOptionIds;
      const deleteOptionIds = prev?.filter((id) => optionIds.find((cur) => cur === id) === undefined);

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

  const handleClickOption = useCallback(
    (optionId: string) => {
      if (field.type === FieldType.SingleSelect) {
        void updateCell([optionId]);
        return;
      }

      const prev = selectedOptionIds;
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

      void updateCell(newOptionIds);
    },
    [field.type, selectedOptionIds, updateCell]
  );

  const handleNewTagClick = useCallback(async () => {
    if (!cell || !rowId) return;
    const option = await createOption();

    if (!option) return;
    handleClickOption(option.id);
  }, [cell, createOption, handleClickOption, rowId]);

  const handleEnter = useCallback(() => {
    if (shouldCreateOption) {
      void handleNewTagClick();
    } else {
      if (field.type === FieldType.SingleSelect) {
        const firstOption = filteredOptions[0];

        if (!firstOption) return;

        void updateCell([firstOption.id]);
      } else {
        void updateCell(filteredOptions.map((option) => option.id));
      }
    }

    setNewOptionName('');
  }, [field.type, filteredOptions, handleNewTagClick, shouldCreateOption, updateCell]);

  return (
    <div className={'text-base'}>
      <SearchInput setNewOptionName={setNewOptionName} newOptionName={newOptionName} onEnter={handleEnter} />
      <div className='mx-4 mb-2 mt-4 text-xs'>
        {shouldCreateOption ? t('grid.selectOption.createNew') : t('grid.selectOption.orSelectOne')}
      </div>
      {shouldCreateOption ? (
        <CreateOption label={newOptionName} onClick={handleNewTagClick} />
      ) : (
        <div className={'max-h-[300px] overflow-y-auto overflow-x-hidden'}>
          {filteredOptions.map((option) => (
            <MenuItem className={'px-2'} key={option.id} value={option.id}>
              <SelectOptionItem
                onClick={() => {
                  handleClickOption(option.id);
                }}
                isSelected={selectedOptionIds?.includes(option.id)}
                fieldId={cell?.fieldId || ''}
                option={option}
              />
            </MenuItem>
          ))}
        </div>
      )}
    </div>
  );
}

export default SelectCellActions;
