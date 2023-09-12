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
import { Database } from '$app/interfaces/database';
import * as service from '../../../database_bd_svc';
import { useViewId } from '../../../database.hooks';
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

export const GridSelectCell: FC<{
  rowId: string;
  field: Database.Field;
  cell: Database.SelectCell | null;
}> = ({ rowId, field, cell }) => {
  const viewId = useViewId();
  const options = useMemo(() => cell?.data?.options ?? [], [cell?.data.options]);
  const selectedIds = useMemo(() => cell?.data.selectOptions?.map(({ id }) => id) ?? [], [cell?.data.selectOptions]);
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
    const prev = cell?.data.selectOptions?.map(({ id }) => id);
    const deleteOptionIds = prev?.filter(id => current.find(cur => cur === id) === undefined);

    void service.updateSelectOptionCell(viewId, rowId, field.id, {
      insertOptionIds: current,
      deleteOptionIds,
    });
  };

  const handleNewTagClick = async () => {
    const exist = options.find(option => option.name.toLowerCase() === newOptionName.toLowerCase());

    if (exist) {
      return service.updateSelectOptionCell(viewId, rowId, field.id, {
        insertOptionIds: [exist.id],
      });
    }

    const option = await service.createSelectOption(viewId, field.id, newOptionName);

    await service.insertOrUpdateSelectOption(viewId, field.id, [option], rowId);
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
        select: 'flex items-center gap-2 px-4 py-2 h-6',
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