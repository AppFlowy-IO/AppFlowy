import React, { FC, FormEvent, useCallback, useMemo, useState } from 'react';
import { t } from 'i18next';
import {
  ListSubheader,
  Select,
  MenuItem,
  OutlinedInput,
  SelectChangeEvent,
  InputBase,
  IconButton,
} from '@mui/material';
import { FieldType } from '@/services/backend';
import { Database } from '$app/interfaces/database';
import { ReactComponent as DetailsSvg } from '$app/assets/details.svg';
import * as service from '../../../database_bd_svc';
import { useViewId } from '../../../database.hooks';
import { Tag } from './Tag';
import { SelectOptionMenu } from './SelectOptionMenu';

export const GridSelectCell: FC<{
  rowId: string;
  field: Database.Field;
  cell: Database.SelectCell | null;
}> = ({ rowId, field, cell }) => {
  const viewId = useViewId();
  const options = cell?.data?.options ?? [];
  const selectedIds = useMemo(() => cell?.data.selectOptions?.map(({ id }) => id )?? [], [cell?.data.selectOptions]);
  const [newOptionName, setNewOptionName] = useState('');
  const [domRef, setDomRef] = useState<HTMLElement | undefined>();
  const [editingOption, setEditingOption] = useState<Database.SelectOption | undefined>();

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

  const handleDetailsClick = useCallback((event: React.MouseEvent, option: Database.SelectOption) => {
    event.stopPropagation();
    setDomRef(event.target as HTMLElement);
    setEditingOption(option);
  }, []);

  return (
    <>
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
        MenuProps={{
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
        }}
        renderValue={(selected) => selected
          .map((id) => options.find(option => option.id === id))
          .map((option) => option && (
            <Tag
              key={option.id}
              size="small"
              color={option.color}
              label={option.name}
            />
          ))}
        onChange={handleChange}
        onClose={handleClose}
      >
        <ListSubheader className="text-xs mb-4">
          {t('grid.selectOption.createTag')}
        </ListSubheader>
        <ListSubheader className="flex">
          <OutlinedInput
            size="small"
            value={newOptionName}
            onInput={handleInput}
          />
        </ListSubheader>
        {newOptionName ? (
          <MenuItem
            className="mt-2 text-xs text-neutral-500 font-medium"
            value={selectedIds}
            onClick={handleNewTagClick}
          >
            {t('grid.selectOption.create')}
            <Tag className="ml-2" size="small" label={newOptionName} />
          </MenuItem>
        ) : null}
        {options.length ? (
          <ListSubheader className="text-xs mt-4 mb-2">
            {t('grid.selectOption.orSelectOne')}
          </ListSubheader>
        ) : null}
        {options.map((option, index) => (
          <MenuItem
            className={index !== options.length - 1 ? 'mb-2' : ''}
            key={option.id}
            value={option.id}
          >
            <div className="flex-1">
              <Tag
                key={option.id}
                size="small"
                color={option.color}
                label={option.name}
              />
            </div>
            <IconButton onClick={event => handleDetailsClick(event, option)}>
              <DetailsSvg className="text-base" />
            </IconButton>
          </MenuItem>
        ))}
      </Select>
      {domRef !== undefined && editingOption !== undefined && (
        <SelectOptionMenu
          open
          option={editingOption}
          MenuProps={{
            anchorEl: domRef,
            onClose: () => {
              setDomRef(undefined);
              setEditingOption(undefined);
            },
          }}
        />)}
    </>
  );
}