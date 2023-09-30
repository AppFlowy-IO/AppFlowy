import { Divider, Menu, MenuItem, MenuProps, OutlinedInput } from '@mui/material';
import { ChangeEventHandler, FC, useCallback, useState } from 'react';
import { ReactComponent as MoreSvg } from '$app/assets/more.svg';
import { Database } from '$app/interfaces/database';
import * as service from '$app/components/database/database_bd_svc';
import { useViewId } from '../../database.hooks';
import { FieldTypeSvg } from './FieldTypeSvg';
import { FieldTypeText } from './FieldTypeText';
import { GridFieldMenuActions } from './GridFieldMenuActions';


export interface GridFieldMenuProps {
  field: Database.Field;
  anchorEl: MenuProps['anchorEl'];
  open: boolean;
  onClose: MenuProps['onClose'];
}

export const GridFieldMenu: FC<GridFieldMenuProps> = ({
  field,
  anchorEl,
  open,
  onClose,
}) => {
  const viewId = useViewId();
  const [inputtingName, setInputtingName] = useState(field.name);

  const handleInput = useCallback<ChangeEventHandler<HTMLInputElement>>((e) => {
    setInputtingName(e.target.value);
  }, []);

  const handleBlur = useCallback(async () => {
    if (inputtingName !== field.name) {
      try {
        await service.updateField(viewId, field.id, {
          name: inputtingName,
        });
      } catch (e) {
        // TODO
        console.error(`change field ${field.id} name from '${field.name}' to ${inputtingName} fail`, e);
      }
    }
  }, [viewId, field, inputtingName]);

  const fieldNameInput = (
    <OutlinedInput
      className="mx-3 mt-1 mb-5 !rounded-[10px]"
      size="small"
      value={inputtingName}
      onChange={handleInput}
      onBlur={handleBlur}
    />
  );

  const fieldTypeSelect = (
    <MenuItem dense>
      <FieldTypeSvg type={field.type} className="text-base mr-2" />
      <span className="flex-1 text-xs font-medium">
        {FieldTypeText(field.type)}
      </span>
      <MoreSvg className="text-base" />
    </MenuItem>
  );

  return (
    <Menu
      anchorEl={anchorEl}
      open={open}
      onClose={onClose}
    >
      {fieldNameInput}
      {fieldTypeSelect}
      <Divider />
      <GridFieldMenuActions />
    </Menu>
  );
};