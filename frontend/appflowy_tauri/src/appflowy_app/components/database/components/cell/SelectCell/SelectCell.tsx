import { FC, FormEvent, useCallback, useMemo, useState } from 'react';
import { t } from 'i18next';
import {
  ListSubheader,
  Select,
  OutlinedInput,
  SelectChangeEvent,
  InputBase,
  MenuProps,
  MenuItem,
} from '@mui/material';
import { FieldType } from '@/services/backend';
import { useViewId } from '$app/hooks';
import { cellService, SelectField, SelectCell as SelectCellType } from '../../../application';
import { Tag } from './Tag';
import { CreateOption } from './CreateOption';
import { SelectOptionItem } from './SelectOptionItem';

const menuProps: Partial<MenuProps> = {
  classes: {
    list: 'py-5',
  },
  anchorOrigin: {
    vertical: 'bottom',
    horizontal: 'left',
  },
  transformOrigin: {
    vertical: 'top',
    horizontal: 'left',
  },
};

export const SelectCell: FC<{
  field: SelectField;
  cell: SelectCellType;
}> = ({ field, cell }) => {
  const rowId = cell.rowId;
  const viewId = useViewId();
  const options = useMemo(() => field.typeOption.options ?? [], [field.typeOption.options]);
  const selectedIds = useMemo(() => cell.data.selectedOptionIds ?? [], [cell.data.selectedOptionIds]);
  const [newOptionName, setNewOptionName] = useState('');
  const filteredOptions = useMemo(() => options.filter(option => {
    return option.name.toLowerCase().includes(newOptionName.toLowerCase());
  }), [options, newOptionName]);

  const shouldCreateOption = !!newOptionName && filteredOptions.length === 0;

  const handleInput = useCallback((event: FormEvent) => {
    const value = (event.target as HTMLInputElement).value;

    setNewOptionName(value);
  }, []);

  const handleClose = useCallback(() => {
    setNewOptionName('');
  }, []);

  const handleChange = (event: SelectChangeEvent<string | string[]>) => {
    const { target: { value } } = event;

    const current = Array.isArray(value) ? value : [value];
    const prev = cell.data.selectedOptionIds;
    const deleteOptionIds = prev?.filter(id => current.find(cur => cur === id) === undefined);

    void cellService.updateSelectCell(viewId, rowId, field.id, {
      insertOptionIds: current,
      deleteOptionIds,
    });
  };

  const handleNewTagClick = async () => {
    const exist = options.find(option => option.name.toLowerCase() === newOptionName.toLowerCase());

    if (exist) {
      return cellService.updateSelectCell(viewId, rowId, field.id, {
        insertOptionIds: [exist.id],
      });
    }

    // const option = await cellService.createSelectOption(viewId, field.id, newOptionName);

    // await cellService.insertOrUpdateSelectOption(viewId, field.id, [option], rowId);
  };

  const searchInput = (
    <ListSubheader className="flex">
      <OutlinedInput
        size="small"
        value={newOptionName}
        onInput={handleInput}
        placeholder={t('grid.selectOption.searchOrCreateOption')}
      />
    </ListSubheader>
  );

  const renderSelectedOptions = useCallback((selected: string[]) => selected
    .map((id) => options.find(option => option.id === id))
    .map((option) => option && (
      <Tag
        key={option.id}
        size="small"
        color={option.color}
        label={option.name}
      />
    )), [options]);

  return (
    <Select
      className="w-full"
      classes={{
        select: 'flex items-center gap-2 px-4 py-1 h-6',
      }}
      size="small"
      value={selectedIds}
      multiple={field.type === FieldType.MultiSelect}
      input={<InputBase />}
      IconComponent={() => null}
      MenuProps={menuProps}
      renderValue={renderSelectedOptions}
      onChange={handleChange}
      onClose={handleClose}
    >
      {searchInput}
      <ListSubheader className="text-xs mt-4 mb-2">
        {shouldCreateOption
          ? t('grid.selectOption.createNew')
          : t('grid.selectOption.orSelectOne')}
      </ListSubheader>
      {shouldCreateOption
        ? <CreateOption label={newOptionName} onClick={handleNewTagClick} />
        : filteredOptions.map((option, index) => (
          <MenuItem
            className={index === 0 ? '' : 'mt-2'}
            key={option.id}
            value={option.id}
          >
            <SelectOptionItem option={option} />
          </MenuItem>
        ))}
    </Select>
  );
};
