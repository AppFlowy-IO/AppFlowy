import React, { FormEvent, useCallback, useMemo, useState } from 'react';
import { ListSubheader, MenuItem, OutlinedInput } from '@mui/material';
import { t } from 'i18next';
import { CreateOption } from '$app/components/database/components/field_types/select/select_cell_actions/CreateOption';
import { SelectOptionItem } from '$app/components/database/components/field_types/select/select_cell_actions/SelectOptionItem';
import { cellService, SelectCell as SelectCellType, SelectField } from '$app/components/database/application';
import { useViewId } from '$app/hooks';
import {
  createSelectOption,
  insertOrUpdateSelectOption,
} from '$app/components/database/application/field/select_option/select_option_service';

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
  const options = useMemo(() => field.typeOption.options ?? [], [field.typeOption.options]);
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

  const handleInput = useCallback((event: FormEvent) => {
    const value = (event.target as HTMLInputElement).value;

    setNewOptionName(value);
  }, []);

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
    [selectedOptionIds, updateCell]
  );

  const handleNewTagClick = useCallback(async () => {
    if (!cell || !rowId) return;
    const option = await createOption();

    if (!option) return;
    handleClickOption(option.id);
  }, [cell, createOption, handleClickOption, rowId]);

  const searchInput = (
    <ListSubheader className='flex'>
      <OutlinedInput
        size='small'
        value={newOptionName}
        onInput={handleInput}
        placeholder={t('grid.selectOption.searchOrCreateOption')}
      />
    </ListSubheader>
  );

  return (
    <div>
      {searchInput}
      <ListSubheader className='mb-2 mt-4 text-xs'>
        {shouldCreateOption ? t('grid.selectOption.createNew') : t('grid.selectOption.orSelectOne')}
      </ListSubheader>
      {shouldCreateOption ? (
        <CreateOption label={newOptionName} onClick={handleNewTagClick} />
      ) : (
        filteredOptions.map((option) => (
          <MenuItem
            onClick={() => {
              handleClickOption(option.id);
            }}
            key={option.id}
            value={option.id}
          >
            <SelectOptionItem
              isSelected={selectedOptionIds?.includes(option.id)}
              fieldId={cell?.fieldId || ''}
              option={option}
            />
          </MenuItem>
        ))
      )}
    </div>
  );
}

export default SelectCellActions;
